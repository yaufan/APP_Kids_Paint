import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/artwork_service.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import 'artwork_stamp.dart';
import 'coloring.dart';
import 'page_image.dart';

enum Tool { bucket, crayon }

/// Coloring a postcard: bucket fill (the default) and a crayon that never
/// leaves the region it started in. On blank paper the crayon (the default
/// there) goes anywhere and the bucket colors the paper behind the drawing.
/// Everything autosaves; "done" sends it.
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

  bool get _blank => _page?.artwork.style == 'blank';

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
      if (_blank) _tool = Tool.crayon;
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

  /// Saves the picture and its thumbnail, then goes to [route].
  Future<void> _saveAnd(String route, {bool push = false}) async {
    final page = _page;
    if (_leaving) return;
    setState(() => _leaving = true);
    if (page != null) {
      await _service.saveFinished(page);
      final files = ref.read(artworkStoreProvider).open(page.artwork.folder);
      await FileImage(files.thumbnail).evict();
      await FileImage(files.colored).evict();
    }
    if (!mounted) return;
    if (push) {
      await context.push(route);
      if (mounted) setState(() => _leaving = false);
    } else {
      context.go(route);
    }
  }

  ({double x, double y}) _toPage(Offset local, double scale) => (x: local.dx / scale, y: local.dy / scale);

  Widget _sheet(LoadedPage page) => LayoutBuilder(builder: (context, box) {
        const pad = 12.0;
        final doc = page.document;
        final scale = math.min((box.maxWidth - 2 * pad - 24) / doc.width, (box.maxHeight - 2 * pad - 24) / doc.height);
        final w = doc.width * scale, h = doc.height * scale;
        final avatar = ref.watch(currentChildProvider).value?.avatar ?? animals.first;
        return Center(
          child: SizedBox(
            width: w + 2 * pad + 24,
            height: h + 2 * pad + 24,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: 12,
                top: 12,
                child: PostcardFrame(
                  tilt: -1,
                  padding: pad,
                  child: SizedBox(
                    key: const ValueKey('page'),
                    width: w,
                    height: h,
                    child: GestureDetector(
                      onTapUp: _tool == Tool.bucket
                          ? (d) {
                              if (_blank) {
                                doc.add(PaperOp(_color));
                                _changed();
                                return;
                              }
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
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(painter: _PagePainter(colors: _colors, lines: _lines!)),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(right: -6, top: -10, child: ArtworkStamp(artwork: page.artwork, width: 72, height: 86)),
              Positioned(right: 26, top: 38, child: Postmark(shortDate(page.artwork.createdAt).replaceAll('/', '.'), size: 52)),
              Positioned(left: -6, bottom: -14, child: Transform.rotate(angle: -0.14, child: AnimalArt(avatar, size: 58))),
            ]),
          ),
        );
      });

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final wide = MediaQuery.sizeOf(context).aspectRatio > 1;
    final color = Color(_color);

    final back = NavButton(icon: 'map', label: Strings.backToMap, color: KidColors.grassDark, onPressed: () => _saveAnd('/'));
    final undo = NavButton(
      icon: 'undo',
      label: Strings.undo,
      color: KidColors.grape,
      onPressed: page != null && page.document.canUndo
          ? () {
              page.document.undo();
              _changed();
            }
          : null,
    );
    final tools = Row(mainAxisSize: MainAxisSize.min, children: [
      _ToolTile(label: _blank ? Strings.paperColor : Strings.bucket, selected: _tool == Tool.bucket, tint: const Color(0xFFFFE6E5),
          onTap: () => setState(() => _tool = Tool.bucket), child: ToolArt(Art.bucket, color: color)),
      const SizedBox(width: 12),
      _ToolTile(label: Strings.crayon, selected: _tool == Tool.crayon, tint: const Color(0xFFFFF1D9),
          onTap: () => setState(() => _tool = Tool.crayon), child: ToolArt(Art.crayon, color: color)),
    ]);
    final palette = _Palette(selected: _color, columns: wide ? 4 : 6, onSelect: (c) => setState(() => _color = c));
    final done = ChunkyButton(
      label: Strings.done,
      onPressed: page != null && page.document.ops.isNotEmpty ? () => _saveAnd('/send/${widget.artworkId}', push: true) : null,
      color: KidColors.grass,
      edge: KidColors.grassDark,
      width: 220,
      height: 76,
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        KidIcon('check', size: 42, color: Colors.white),
        SizedBox(width: 10),
        KidIcon('mail', size: 30, color: Colors.white),
      ]),
    );
    final sheet = page == null || _lines == null ? const Center(child: BouncingDots()) : _sheet(page);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAnd('/');
      },
      child: Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Stack(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: wide
                    ? Row(children: [
                        Column(children: [back, const SizedBox(height: 14), undo]),
                        const SizedBox(width: 12),
                        Expanded(child: sheet),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 300,
                          child: Column(children: [
                            tools,
                            const SizedBox(height: 16),
                            palette,
                            const Spacer(),
                            done,
                          ]),
                        ),
                      ])
                    : Column(children: [
                        Row(children: [
                          back,
                          const Spacer(),
                          if (page != null) InfoChip(icon: 'clock', text: shortDate(page.artwork.createdAt)),
                          const Spacer(),
                          undo,
                        ]),
                        const SizedBox(height: 8),
                        Expanded(child: sheet),
                        const SizedBox(height: 14),
                        tools,
                        const SizedBox(height: 12),
                        palette,
                        const SizedBox(height: 14),
                        done,
                      ]),
              ),
              if (_leaving) const ModalBarrier(dismissible: false),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A drawn tool on a tile; the chosen one jumps up.
class _ToolTile extends StatelessWidget {
  const _ToolTile({required this.label, required this.selected, required this.tint, required this.onTap, required this.child});

  final String label;
  final bool selected;
  final Color tint;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          width: KidTheme.toolButton,
          height: 70,
          transform: Matrix4.translationValues(0, selected ? -6 : 0, 0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? tint : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: selected ? HSLColor.fromColor(tint).withLightness(0.82).toColor() : const Color(0xFFE8E2D6), offset: Offset(0, selected ? 8 : 4))],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Twelve paint pots; the chosen one is bigger with a ring.
class _Palette extends StatelessWidget {
  const _Palette({required this.selected, required this.onSelect, this.columns = 6});

  final int selected;
  final ValueChanged<int> onSelect;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: KidShadows.soft()),
      child: GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 6,
        children: [
          for (var i = 0; i < kidPalette.length; i++)
            Center(child: _Pot(key: ValueKey('swatch-${kidPalette[i]}'), color: kidPalette[i], name: kidPaletteNames[i], selected: kidPalette[i] == selected, onTap: () => onSelect(kidPalette[i]))),
        ],
      ),
    );
  }
}

class _Pot extends StatelessWidget {
  const _Pot({super.key, required this.color, required this.name, required this.selected, required this.onTap});

  final int color;
  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    final white = c.computeLuminance() > 0.9;
    final size = selected ? 50.0 : 44.0;
    return Semantics(
      button: true,
      selected: selected,
      label: Strings.colorName(name),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? (white ? KidColors.inkSoft : c) : Colors.white, width: selected ? 3 : 4),
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 0.9,
              colors: [Color.lerp(c, Colors.white, 0.65)!, c, c],
              stops: const [0, 0.32, 1],
            ),
            boxShadow: [
              if (white) const BoxShadow(color: Color(0xFFE3E8E4), spreadRadius: 1),
              BoxShadow(color: HSLColor.fromColor(c).withLightness((HSLColor.fromColor(c).lightness - 0.12).clamp(0.0, 1.0)).toColor(), offset: const Offset(0, 3)),
            ],
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
