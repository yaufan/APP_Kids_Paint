import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import '../canvas/page_image.dart';
import '../capture/paper_photo.dart';
import 'line_art.dart';

/// The photo turns into coloring pages ("magic"), then the child taps the
/// style they like. No settings: detail is a parent option (default simple).
/// A photo of a drawing on [paper] (0.18) is cleaned up instead and goes
/// straight onto the canvas.
class StylePickerScreen extends ConsumerStatefulWidget {
  const StylePickerScreen({super.key, required this.photo, this.detail = DetailLevel.simple, this.paper = false});

  final Uint8List photo;
  final DetailLevel detail;
  final bool paper;

  /// The magic lasts at least this long, even when converting is quicker.
  static const magicTime = Duration(milliseconds: 1800);

  @override
  ConsumerState<StylePickerScreen> createState() => _StylePickerScreenState();
}

class _StylePickerScreenState extends ConsumerState<StylePickerScreen> {
  late final Future<List<LineArt>> _pages;
  late final Future<PaperDrawing?> _paper;
  bool _saving = false;

  /// The drawing on paper could not be found or kept.
  bool _paperFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.paper) {
      _paper = Future.wait([
        _cleanPaper(widget.photo),
        Future<void>.delayed(StylePickerScreen.magicTime),
      ]).then((both) => both.first as PaperDrawing?);
      _paper.then(_keepPaper, onError: (_) => _keepPaper(null));
      return;
    }
    final engine = ref.read(lineArtEngineProvider);
    _pages = Future.wait([
      Future.wait([for (final style in ArtStyle.values) engine.convert(widget.photo, style, widget.detail)]),
      Future<void>.delayed(StylePickerScreen.magicTime),
    ]).then((both) => both.first as List<LineArt>);
  }

  /// Off the screen's thread; static, so nothing of the screen goes along.
  static Future<PaperDrawing?> _cleanPaper(Uint8List photo) => Isolate.run(() => paperDrawing(photo));

  Future<void> _keepPaper(PaperDrawing? drawing) async {
    if (!mounted) return;
    if (drawing == null) return setState(() => _paperFailed = true);
    try {
      final child = await ref.read(currentChildProvider.future);
      final artwork = await ref.read(artworkServiceProvider).savePaper(childId: child.id, photo: widget.photo, drawing: drawing);
      if (mounted) context.go('/canvas/${artwork.id}');
    } catch (_) {
      if (mounted) setState(() => _paperFailed = true);
    }
  }

  Future<void> _choose(ArtStyle style, LineArt page) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final child = await ref.read(currentChildProvider.future);
      final artwork = await ref.read(artworkServiceProvider).saveNew(
            childId: child.id,
            photo: widget.photo,
            page: page,
            style: style,
            detail: widget.detail,
          );
      if (mounted) context.go('/canvas/${artwork.id}');
    } catch (_) {
      // The phone could not keep it (full, say): the child can tap again.
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _failed(String text) => Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Stack(children: [
              Center(child: VoiceBubble(text)),
              Positioned(left: 14, top: 12, child: NavButton(icon: 'back', label: Strings.retake, onPressed: () => context.pop())),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(currentChildProvider).value?.avatar ?? animals.first;
    if (widget.paper) return _paperFailed ? _failed(Strings.paperNotFound) : _Magic(photo: widget.photo, avatar: avatar);
    return FutureBuilder<List<LineArt>>(
      future: _pages,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _failed(Strings.convertFailed);
        final pages = snapshot.data;
        if (pages == null || _saving) return _Magic(photo: widget.photo, avatar: avatar);
        return _Choice(
          pages: pages,
          avatar: avatar,
          onChoose: _choose,
          onBack: () => context.pop(),
        );
      },
    );
  }
}

/// While the page is made: the child's animal waves a wand and a stripe of
/// light sweeps over the photo. Stars fill up instead of a progress bar.
class _Magic extends StatefulWidget {
  const _Magic({required this.photo, required this.avatar});

  final Uint8List photo;
  final String avatar;

  @override
  State<_Magic> createState() => _MagicState();
}

class _MagicState extends State<_Magic> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  final _stars = 3;
  late final DateTime _start = DateTime.now();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lit = (DateTime.now().difference(_start).inMilliseconds / 700).floor().clamp(0, _stars - 1) + 1;
    final name = animalNames[widget.avatar] ?? '';
    return Scaffold(
      backgroundColor: KidColors.night,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [Color(0xFF6E57FF), Color(0xFF3B2FB5), Color(0xFF221C70)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            final card = math.min(box.maxWidth - 60, box.maxHeight * 0.42);
            return Column(children: [
              const SizedBox(height: 28),
              const Text(Strings.magic, style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: 2)),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const KidIcon('sound', size: 18, color: Color(0xFFCFC7FF)),
                const SizedBox(width: 6),
                Text(Strings.magicHint(name), style: const TextStyle(color: Color(0xFFCFC7FF), fontSize: 15)),
              ]),
              const Spacer(),
              Container(
                width: card,
                height: card,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(color: Colors.white.withValues(alpha: 0.18), spreadRadius: 8),
                    const BoxShadow(color: Color(0x800A053C), blurRadius: 50, offset: Offset(0, 24)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => CustomPaint(
                      foregroundPainter: _WandLightPainter(Curves.easeInOut.transform(_c.value)),
                      child: SizedBox.expand(child: Image.memory(widget.photo, fit: BoxFit.cover, gaplessPlayback: true)),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Transform.rotate(angle: -0.1, child: AnimalArt(widget.avatar, size: 110)),
                AnimatedBuilder(
                  animation: _c,
                  builder: (context, child) => Transform.rotate(angle: -0.6 + 0.5 * _c.value, alignment: Alignment.bottomLeft, child: child),
                  child: const SizedBox(width: 70, height: 90, child: CustomPaint(painter: _WandPainter())),
                ),
              ]),
              const SizedBox(height: 24),
              Semantics(
                label: '$lit / $_stars',
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < _stars; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: i < lit
                          ? const KidIcon('star', size: 44, color: Color(0xFFFFD23F), solid: true)
                          : const KidIcon('star', size: 44, color: Color(0xFF8D80E6)),
                    ),
                ]),
              ),
              const SizedBox(height: 40),
            ]);
          }),
        ),
      ),
    );
  }
}

/// A glowing diagonal stripe sweeping over the photo.
class _WandLightPainter extends CustomPainter {
  _WandLightPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width * 0.3 + t * size.width * 1.6;
    final a = Offset(x, 0), b = Offset(x - size.width * 0.35, size.height);
    canvas.drawLine(a, b, Paint()
      ..color = const Color(0x8CFFE27A)
      ..strokeWidth = 22
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawLine(a, b, Paint()
      ..color = Colors.white
      ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(_WandLightPainter old) => old.t != t;
}

class _WandPainter extends CustomPainter {
  const _WandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final a = Offset(4, size.height - 4), b = Offset(size.width * 0.75, size.height * 0.25);
    canvas.drawLine(a, b, Paint()
      ..color = const Color(0xFF5A3A20)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    canvas.drawLine(a, b, Paint()
      ..color = const Color(0xFFC98B5E)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final r = i.isEven ? 13.0 : 4.0;
      final angle = i * math.pi / 4 - math.pi / 2;
      final p = b + Offset(math.cos(angle) * r, math.sin(angle) * r);
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = const Color(0xFFFFE27A));
  }

  @override
  bool shouldRepaint(_WandPainter old) => false;
}

/// Both styles as postcards; the child taps the one they like.
class _Choice extends StatelessWidget {
  const _Choice({required this.pages, required this.avatar, required this.onChoose, required this.onBack});

  final List<LineArt> pages;
  final String avatar;
  final void Function(ArtStyle style, LineArt page) onChoose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).aspectRatio > 1;
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDDF2FF), Color(0xFFFFF6E8)], stops: [0, 0.7]),
        ),
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(children: [
                NavButton(icon: 'back', label: Strings.retake, onPressed: onBack),
                const SizedBox(width: 10),
                AnimalArt(avatar, size: 60),
                const SizedBox(width: 6),
                const Flexible(child: VoiceBubble(Strings.whichOne)),
              ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  children: [
                    for (final style in ArtStyle.values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: PopIn(
                            delay: Duration(milliseconds: 140 * style.index),
                            child: _StyleCard(style: style, page: pages[style.index], onTap: () => onChoose(style, pages[style.index])),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.style, required this.page, required this.onTap});

  final ArtStyle style;
  final LineArt page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final realistic = style == ArtStyle.realistic;
    return Semantics(
      button: true,
      label: realistic ? Strings.realistic : Strings.cute,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: PostcardFrame(
              tilt: realistic ? -2.5 : 2.5,
              radius: 24,
              child: Center(child: GrayPagePreview(gray: page.lines, width: page.width, height: page.height)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: -12,
            child: Center(
              child: Transform.rotate(
                angle: -0.05,
                child: Container(width: 72, height: 24, color: (realistic ? const Color(0xFF9ED8FF) : const Color(0xFFFFC2D4)).withValues(alpha: 0.85)),
              ),
            ),
          ),
          Positioned(
            left: -14,
            top: -14,
            child: Container(
              width: 66,
              height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: realistic ? KidColors.sky : KidColors.pink,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: KidShadows.soft(),
              ),
              child: KidIcon(realistic ? 'camera' : 'sparkle', size: 30, color: Colors.white, solid: !realistic),
            ),
          ),
        ]),
      ),
    );
  }
}
