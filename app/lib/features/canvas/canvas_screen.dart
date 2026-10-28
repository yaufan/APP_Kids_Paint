import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/artwork_service.dart';
import '../../core/creatures.dart';
import '../../core/db/database.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import 'artwork_stamp.dart';
import 'coloring.dart';
import 'page_image.dart';

enum Tool { bucket, crayon, rainbow, glitter, stamp, eraser }

const _stampNames = {StampShape.star: '星星', StampShape.heart: '愛心', StampShape.flower: '花朵', StampShape.paw: '腳印'};

/// The kinds of pen under 魔法畫筆: what it draws with, how thick (a part of
/// the page's width), what it is called.
const _pens = [
  (Brush.crayon, 0.02, Strings.penCrayon),
  (Brush.crayon, 0.045, Strings.penThick),
  (Brush.dots, 0.022, Strings.penDots),
  (Brush.spray, 0.05, Strings.penSpray),
  (Brush.watercolor, 0.035, Strings.penWatercolor),
  (Brush.neon, 0.03, Strings.penNeon),
  (Brush.stripes, 0.03, Strings.penStripes),
];

/// Coloring a postcard: bucket fill (the default), and brushes that never
/// leave the region they started in (the magic pen in its seven kinds,
/// rainbow, glitter, eraser), and stamps. On blank paper the crayon (the default there) goes anywhere and
/// the bucket colors the paper behind the drawing. Everything autosaves;
/// "done" sends it.
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
  StampShape _shape = StampShape.star;

  /// One of the child's own pictures to stamp with instead of [_shape].
  Artwork? _picture;
  bool _pressing = false;
  int _pen = 0; // which of [_pens]
  int _paletteSet = 0; // which of [kidPaletteSets]
  int _color = kidPalette.first;
  CrayonOp? _stroke;
  bool _refreshing = false;
  bool _dirty = false;
  bool _leaving = false;

  ArtworkService get _service => ref.read(artworkServiceProvider);

  void _sound(Sfx sfx) => ref.read(soundsProvider).play(sfx);

  bool get _blank => _page?.artwork.style == 'blank';

  /// A zoo or aquarium creature: it moves into its scene instead of being mailed.
  Creature? get _creature => Creature.byName(_page?.artwork.template);

  /// Where "back" goes: the creature's scene, or the town.
  String get _home => _creature == null ? '/' : '/scene/${_creature!.habitat.name}';

  /// Finishes a creature, puts it on the map at its scene's place, and
  /// opens the scene, where it arrives.
  Future<void> _moveIn(Creature creature) async {
    final page = _page;
    if (page == null || _leaving) return;
    setState(() => _leaving = true);
    try {
      final place = await ref.read(placeRepositoryProvider).defaultPlace(page.artwork.childId, creature.habitat.place);
      await _service.send(page, place);
      await _evictPictures(page);
    } catch (_) {
      return _couldNotSave();
    }
    if (mounted) context.go('/scene/${creature.habitat.name}?new=${page.artwork.id}');
  }

  /// The pictures of [page] cached for the screens it shows up on.
  Future<void> _evictPictures(LoadedPage page) async {
    final files = ref.read(artworkStoreProvider).open(page.artwork.folder);
    for (final file in [files.thumbnail, files.colored, files.sprite]) {
      await FileImage(file).evict();
    }
  }

  /// Saving failed (the phone is full, say): the picture stays open and can
  /// be tried again, nothing is stuck.
  void _couldNotSave() {
    if (!mounted) return;
    setState(() => _leaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.saveFailed)));
  }

  /// A page from the app (blank paper, a festival's or a creature's) left
  /// without a single mark and never sent: nothing to keep, so it goes.
  bool _untouched(LoadedPage page) =>
      page.document.ops.isEmpty && page.artwork.sentAt == null && const {'blank', 'template'}.contains(page.artwork.style);

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
    try {
      if (page != null && !push && _untouched(page)) {
        await _service.delete(page.artwork);
      } else if (page != null) {
        await _service.saveFinished(page);
        await _evictPictures(page);
      }
    } catch (_) {
      return _couldNotSave();
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

  /// The brush in hand, if the tool is one.
  Brush? get _brush => switch (_tool) {
        Tool.crayon => _pens[_pen].$1,
        Tool.rainbow => Brush.rainbow,
        Tool.glitter => Brush.glitter,
        Tool.eraser => Brush.eraser,
        Tool.bucket || Tool.stamp => null,
      };

  void _tapPage(Offset local, double scale, ColoringDocument doc) {
    final p = _toPage(local, scale);
    switch (_tool) {
      case Tool.bucket:
        if (_blank) {
          doc.add(PaperOp(_color));
          _sound(Sfx.fill);
          _changed();
        } else if (doc.fill(p.x, p.y, _color)) {
          _sound(Sfx.fill);
          _changed();
        }
      case Tool.stamp:
        if (_picture != null) {
          _pressPicture(_picture!, p, doc);
          return;
        }
        final region = doc.regions.labelAt(p.x.floor(), p.y.floor());
        if (region == 0) return;
        doc.add(StampOp(region, _color, _shape, p.x, p.y, doc.width * 0.075));
        _sound(Sfx.stamp);
        _changed();
      case Tool.crayon || Tool.rainbow || Tool.glitter || Tool.eraser:
        // A tap with a brush leaves a dot.
        _startStroke(p, doc);
        _endStroke();
    }
  }

  /// Presses one of the child's own pictures onto the page, a copy of it
  /// kept with the page.
  Future<void> _pressPicture(Artwork source, PagePoint p, ColoringDocument doc) async {
    final page = _page;
    if (page == null || _pressing) return;
    _pressing = true;
    try {
      if (!doc.pictures.containsKey(source.folder)) {
        final (name, picture) = await _service.copyPicture(source, page.artwork);
        doc.pictures[name] = picture;
      }
      if (!mounted) return;
      doc.add(PictureOp(source.folder, p.x, p.y, doc.width * 0.32));
      _sound(Sfx.stamp);
      _changed();
    } catch (_) {
      // Its cut-out is gone: nothing happens.
    } finally {
      _pressing = false;
    }
  }

  void _startStroke(PagePoint p, ColoringDocument doc) {
    final brush = _brush;
    final region = doc.regions.labelAt(p.x.floor(), p.y.floor());
    if (brush == null || region == 0) return;
    final size = switch (_tool) {
      Tool.crayon => _pens[_pen].$2,
      Tool.rainbow => 0.024,
      Tool.glitter => 0.03,
      _ => 0.035, // the eraser
    };
    _stroke = CrayonOp(region, _color, doc.width * size, [p], brush: brush);
    doc.add(_stroke!);
    _sound(switch (brush) {
      Brush.rainbow || Brush.glitter || Brush.neon => Sfx.sparkle,
      Brush.eraser => Sfx.squeak,
      _ => Sfx.swish,
    });
    _refreshColors();
  }

  void _endStroke() {
    if (_stroke != null) _changed();
    _stroke = null;
  }

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
                      onTapUp: (d) => _tapPage(d.localPosition, scale, doc),
                      onPanStart: _brush != null ? (d) => _startStroke(_toPage(d.localPosition, scale), doc) : null,
                      onPanUpdate: _brush != null
                          ? (d) {
                              final stroke = _stroke;
                              if (stroke == null) return;
                              stroke.points.add(_toPage(d.localPosition, scale));
                              doc.applyStroke(stroke, stroke.points.length - 1);
                              _refreshColors();
                            }
                          : null,
                      onPanEnd: _brush != null ? (_) => _endStroke() : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(painter: PagePainter(colors: _colors, lines: _lines!)),
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

    final creature = _creature;
    final back = NavButton(
      icon: 'map',
      label: creature == null ? Strings.backToMap : Strings.backTo(creature.habitat.place.label),
      color: KidColors.grassDark,
      onPressed: () => _saveAnd(_home),
    );
    final undo = NavButton(
      icon: 'undo',
      label: Strings.undo,
      color: KidColors.grape,
      onPressed: page != null && page.document.canUndo
          ? () {
              page.document.undo();
              _sound(Sfx.undo);
              _changed();
            }
          : null,
    );
    final tileWidth = wide ? 64.0 : 52.0;
    final art = tileWidth * 0.62;
    Widget tool(Tool t, String label, Color tint, Widget child) => _ToolTile(
        label: label, width: tileWidth, selected: _tool == t, tint: tint, onTap: () {
          _sound(Sfx.tap);
          setState(() => _tool = t);
        }, child: child);
    final tools = Wrap(alignment: WrapAlignment.center, spacing: wide ? 12 : 6, runSpacing: 14, children: [
      tool(Tool.bucket, _blank ? Strings.paperColor : Strings.bucket, const Color(0xFFFFE6E5), ToolArt(Art.bucket, color: color, size: art)),
      tool(Tool.crayon, Strings.crayon, const Color(0xFFFFF1D9), ToolArt(Art.crayon, color: color, size: art)),
      tool(Tool.rainbow, Strings.rainbow, const Color(0xFFEDE6FF), ArtSvg(Art.rainbow, width: art, height: art * 1.2)),
      tool(Tool.glitter, Strings.glitter, const Color(0xFFFFF6C9), ToolArt(Art.glitter, color: color, size: art)),
      tool(Tool.stamp, Strings.stamp, const Color(0xFFE3F4FB), ToolArt(Art.stamp, color: color, size: art)),
      tool(Tool.eraser, Strings.eraser, const Color(0xFFFFE3EA), ArtSvg(Art.eraser, width: art, height: art * 1.2)),
    ]);
    final childId = ref.watch(currentChildProvider).value?.id;
    final pictures = [
      for (final a in (childId == null ? null : ref.watch(stampPicturesProvider(childId)).value) ?? const <Artwork>[])
        if (a.id != widget.artworkId) a,
    ];
    final store = ref.watch(artworkStoreProvider);
    Widget stampTile({Key? key, required bool selected, required String label, required VoidCallback onTap, required Widget child}) => Padding(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            excludeSemantics: true,
            child: Pressable(
              onTap: () {
                _sound(Sfx.tap);
                onTap();
              },
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? (color.computeLuminance() > 0.9 ? KidColors.inkSoft : color) : Colors.white, width: 3),
                  boxShadow: KidShadows.soft(),
                ),
                child: child,
              ),
            ),
          ),
        );
    final shapes = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final shape in StampShape.values)
          stampTile(
            selected: _picture == null && shape == _shape,
            label: Strings.stampOf(_stampNames[shape]!),
            onTap: () => setState(() {
              _shape = shape;
              _picture = null;
            }),
            child: SvgPicture.asset(Art.stampShape(shape.name), width: 32, height: 32,
                colorFilter: ColorFilter.mode(color.computeLuminance() > 0.9 ? KidColors.inkSoft : color, BlendMode.srcIn)),
          ),
        for (final a in pictures)
          stampTile(
            key: ValueKey('picture-stamp-${a.id}'),
            selected: _picture?.id == a.id,
            label: Strings.pictureStamp,
            onTap: () => setState(() => _picture = a),
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Image(image: FileImage(store.open(a.folder).sprite), fit: BoxFit.contain, gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
          ),
      ]),
    );
    final pens = Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 8, children: [
      for (final (i, (brush, _, name)) in _pens.indexed)
        Semantics(
          button: true,
          selected: i == _pen,
          label: name,
          excludeSemantics: true,
          child: Pressable(
            onTap: () {
              _sound(Sfx.tap);
              setState(() => _pen = i);
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: i == _pen ? (color.computeLuminance() > 0.9 ? KidColors.inkSoft : color) : Colors.white, width: 3),
                boxShadow: KidShadows.soft(),
              ),
              child: CustomPaint(painter: _PenSample(brush, thick: i == 1, color: color.computeLuminance() > 0.9 ? KidColors.inkSoft : color)),
            ),
          ),
        ),
    ]);
    final palette = _Palette(
      selected: _color,
      columns: wide ? 4 : 6,
      set: _paletteSet,
      onSelect: (c) {
        _sound(Sfx.pick);
        setState(() => _color = c);
      },
      onSet: (i) {
        _sound(Sfx.tap);
        setState(() => _paletteSet = i);
      },
    );
    final done = ChunkyButton(
      label: Strings.done,
      onPressed: page != null && page.document.ops.isNotEmpty
          ? () {
              if (creature != null) {
                _moveIn(creature); // the place cheers when it arrives
              } else {
                _sound(Sfx.tada);
                _saveAnd('/send/${widget.artworkId}', push: true);
              }
            }
          : null,
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
        if (!didPop) _saveAnd(_home);
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
                            if (_tool == Tool.stamp) ...[const SizedBox(height: 14), shapes],
                            if (_tool == Tool.crayon) ...[const SizedBox(height: 14), pens],
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
                        if (_tool == Tool.stamp) ...[const SizedBox(height: 10), shapes],
                        if (_tool == Tool.crayon) ...[const SizedBox(height: 10), pens],
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
  const _ToolTile({required this.label, required this.selected, required this.tint, required this.onTap, required this.child, this.width = KidTheme.toolButton});

  final String label;
  final double width;
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
          width: width,
          height: width + 8,
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

/// Twelve paint pots of one set of colors (the chosen one bigger, with a
/// ring), and beside them a button for each set: a little wheel of its colors.
class _Palette extends StatelessWidget {
  const _Palette({required this.selected, required this.onSelect, required this.set, required this.onSet, this.columns = 6});

  final int selected;
  final ValueChanged<int> onSelect;

  /// Which of [kidPaletteSets] shows.
  final int set;
  final ValueChanged<int> onSet;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final colors = kidPaletteSets[set];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 6, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: KidShadows.soft()),
      child: Row(children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            children: [
              for (var i = 0; i < colors.colors.length; i++)
                Center(
                  child: _Pot(
                    key: ValueKey('swatch-${colors.colors[i]}'),
                    color: colors.colors[i],
                    name: colors.names[i],
                    selected: colors.colors[i] == selected,
                    onTap: () => onSelect(colors.colors[i]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (i, s) in kidPaletteSets.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Semantics(
                button: true,
                selected: i == set,
                label: s.name,
                excludeSemantics: true,
                child: Pressable(
                  key: ValueKey('palette-$i'),
                  onTap: () => onSet(i),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: i == set ? KidColors.ink : Colors.white, width: 3),
                      gradient: SweepGradient(colors: [
                        for (final k in const [0, 2, 5, 7, 0]) Color(s.colors[k]),
                      ]),
                      boxShadow: KidShadows.soft(),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ]),
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

/// What a kind of pen draws, as a little wavy line on its button.
class _PenSample extends CustomPainter {
  _PenSample(this.brush, {required this.color, this.thick = false});

  final Brush brush;
  final Color color;
  final bool thick;

  @override
  void paint(Canvas canvas, Size size) {
    final wave = [
      for (var i = 0; i <= 20; i++)
        Offset(size.width * (0.18 + 0.64 * i / 20), size.height * (0.5 + 0.18 * math.sin(i / 20 * 2 * math.pi))),
    ];
    final path = Path()..addPolygon(wave, false);
    Paint pen(double width, Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pale = Color.lerp(color, Colors.white, 0.6)!;
    switch (brush) {
      case Brush.dots:
        for (final p in [wave[0], wave[5], wave[10], wave[15], wave[20]]) {
          canvas.drawCircle(p, 3.6, Paint()..color = color);
        }
      case Brush.spray:
        final r = math.Random(3);
        for (var i = 0; i < 90; i++) {
          final p = wave[r.nextInt(wave.length)];
          final a = r.nextDouble() * 2 * math.pi, d = 6 * math.sqrt(r.nextDouble());
          canvas.drawCircle(p + Offset(math.cos(a) * d, math.sin(a) * d), 0.9, Paint()..color = color);
        }
      case Brush.watercolor:
        canvas.drawPath(path, pen(10, color.withValues(alpha: 0.45)));
        canvas.drawPath(path.shift(const Offset(0, 4)), pen(8, color.withValues(alpha: 0.35)));
      case Brush.neon:
        canvas.drawPath(path, pen(12, Color.lerp(color, Colors.white, 0.55)!));
        canvas.drawPath(path, pen(7, color));
        canvas.drawPath(path, pen(2.5, Color.lerp(color, Colors.white, 0.8)!));
      case Brush.stripes:
        for (var i = 0; i < 20; i += 2) {
          canvas.drawLine(wave[i], wave[i + 2], pen(7, (i ~/ 2).isEven ? color : pale)..strokeCap = StrokeCap.butt);
        }
      case _:
        canvas.drawPath(path, pen(thick ? 11 : 5, color));
    }
  }

  @override
  bool shouldRepaint(_PenSample old) => old.brush != brush || old.color != color || old.thick != thick;
}
