import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/scene.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/artwork_service.dart';
import '../../core/providers.dart';
import 'coloring.dart';
import 'crayon_tray.dart';
import 'page_image.dart';

enum Tool { bucket, crayon }

/// The coloring canvas: bucket fill (the default) and a crayon that never
/// leaves the region it started in. Everything autosaves.
class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key, required this.artworkId});

  final int artworkId;

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  LoadedPage? _page;
  ui.Image? _lines;
  ui.Image? _colors;
  Tool _tool = Tool.bucket;
  int _color = kidPalette.first;
  CrayonOp? _stroke;
  bool _refreshing = false;
  bool _dirty = false;
  bool _leaving = false;

  ArtworkService get _service => ref.read(artworkServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final page = await _service.load(widget.artworkId);
    final doc = page.document;
    final lines = await grayToImage(page.lines, doc.width, doc.height);
    if (!mounted) return;
    setState(() {
      _page = page;
      _lines = lines;
    });
    _refreshColors();
  }

  @override
  void dispose() {
    _lines?.dispose();
    _colors?.dispose();
    super.dispose();
  }

  /// Re-uploads the color layer; at most one upload runs at a time.
  Future<void> _refreshColors() async {
    final doc = _page?.document;
    if (doc == null) return;
    if (_refreshing) {
      _dirty = true;
      return;
    }
    _refreshing = true;
    do {
      _dirty = false;
      final image = await rgbaToImage(Uint8List.fromList(doc.rgba), doc.width, doc.height);
      if (!mounted) {
        image.dispose();
        return;
      }
      final old = _colors;
      setState(() => _colors = image);
      old?.dispose();
    } while (_dirty);
    _refreshing = false;
  }

  void _changed() {
    _refreshColors();
    final page = _page;
    if (page != null) _service.saveOps(page.artwork, page.document);
  }

  Future<void> _leave() async {
    final page = _page;
    if (_leaving) return;
    setState(() => _leaving = true);
    if (page != null) {
      await _service.saveFinished(page);
      final files = ref.read(artworkStoreProvider).open(page.artwork.folder);
      await FileImage(files.thumbnail).evict();
    }
    if (mounted) context.go('/');
  }

  // Page coordinates from a position on the displayed canvas.
  ({double x, double y}) _toPage(Offset local, double scale) => (x: local.dx / scale, y: local.dy / scale);

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final wide = MediaQuery.sizeOf(context).aspectRatio > 1;

    Widget toolButton(Tool tool, IconData icon, String label, Color color) => KidButton(
          icon: icon,
          label: label,
          color: color,
          shape: StickerShape.rounded,
          size: KidTheme.toolButton,
          selected: _tool == tool,
          onPressed: () => setState(() => _tool = tool),
        );
    final nav = [
      HomeButton(onPressed: _leave),
      KidButton(
        icon: Icons.undo_rounded,
        label: Strings.undo,
        color: KidColors.lavender,
        size: KidTheme.toolButton,
        onPressed: page != null && page.document.canUndo
            ? () {
                page.document.undo();
                _changed();
              }
            : null,
      ),
    ];
    final tools = [
      toolButton(Tool.bucket, Icons.format_color_fill_rounded, Strings.bucket, KidColors.sky),
      toolButton(Tool.crayon, Icons.brush_rounded, Strings.crayon, KidColors.grass),
    ];
    const gap = SizedBox.square(dimension: 14);
    final tray = CrayonTray(selected: _color, onSelect: (c) => setState(() => _color = c), vertical: wide);

    final sheet = page == null || _lines == null
        ? const Center(child: BouncingDots())
        : LayoutBuilder(builder: (context, box) {
            const margin = 14.0, border = 3.0;
            final doc = page.document;
            final room = 2 * (margin + border);
            final scale = math.min(
              (box.maxWidth - room) / doc.width,
              (box.maxHeight - room - KidTheme.depth) / doc.height,
            );
            return Center(
              child: StickerCard(
                padding: const EdgeInsets.all(margin),
                radius: 20,
                child: SizedBox(
                  key: const ValueKey('page'),
                  width: doc.width * scale,
                  height: doc.height * scale,
                  child: GestureDetector(
                    onTapUp: _tool == Tool.bucket
                        ? (d) {
                            final p = _toPage(d.localPosition, scale);
                            if (doc.fill(p.x, p.y, _color)) _changed();
                          }
                        : null,
                    onPanStart: _tool == Tool.crayon
                        ? (d) {
                            final p = _toPage(d.localPosition, scale);
                            final region = doc.regions.labelAt(p.x.floor(), p.y.floor());
                            if (region == 0) return;
                            _stroke = CrayonOp(region, _color, doc.width * 0.02, [p]);
                            doc.add(_stroke!);
                            _refreshColors();
                          }
                        : null,
                    onPanUpdate: _tool == Tool.crayon
                        ? (d) {
                            final stroke = _stroke;
                            if (stroke == null) return;
                            stroke.points.add(_toPage(d.localPosition, scale));
                            doc.applyStroke(stroke, stroke.points.length - 1);
                            _refreshColors();
                          }
                        : null,
                    onPanEnd: _tool == Tool.crayon
                        ? (_) {
                            if (_stroke != null) _changed();
                            _stroke = null;
                          }
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CustomPaint(painter: _PagePainter(colors: _colors, lines: _lines!)),
                    ),
                  ),
                ),
              ),
            );
          });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: wide
                      ? Row(children: [
                          Column(children: [...nav.expand((w) => [w, gap]), const Spacer(), ...tools.expand((w) => [gap, w])]),
                          gap,
                          Expanded(child: sheet),
                          gap,
                          tray,
                        ])
                      : Column(children: [
                          Row(children: [...nav.expand((w) => [w, gap]), const Spacer(), ...tools.expand((w) => [gap, w])]),
                          gap,
                          Expanded(child: sheet),
                          gap,
                          tray,
                        ]),
                ),
                if (_leaving) const ModalBarrier(color: Colors.black26, dismissible: false),
                if (_leaving) const Center(child: BouncingDots()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Color layer underneath, line art multiplied on top: lines never get covered.
class _PagePainter extends CustomPainter {
  _PagePainter({required this.colors, required this.lines});

  final ui.Image? colors;
  final ui.Image lines;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    final src = Rect.fromLTWH(0, 0, lines.width.toDouble(), lines.height.toDouble());
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (colors != null) {
      canvas.drawImageRect(colors!, src, dst, paint);
    } else {
      canvas.drawRect(dst, Paint()..color = Colors.white);
    }
    canvas.drawImageRect(lines, src, dst, paint..blendMode = BlendMode.multiply);
  }

  @override
  bool shouldRepaint(_PagePainter old) => old.colors != colors || old.lines != lines;
}
