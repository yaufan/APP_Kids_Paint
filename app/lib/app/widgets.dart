import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art.dart';
import 'strings.dart';
import 'theme.dart';

/// Squishes when pressed and springs back when released, so every tap feels
/// like poking a toy.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _squish = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 480),
  );

  @override
  void dispose() {
    _squish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _squish.forward() : null,
      onTapCancel: () => _squish.reverse(),
      onTapUp: enabled ? (_) => _squish.reverse() : null,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _squish,
        builder: (context, child) {
          // Elastic on the way back: a little overshoot, like rubber.
          final t = _squish.status == AnimationStatus.reverse
              ? Curves.elasticIn.transform(_squish.value)
              : Curves.easeOut.transform(_squish.value);
          return Transform.scale(scaleX: 1 - 0.08 * t, scaleY: 1 - 0.11 * t, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

/// Gently grows and shrinks to invite the first tap on a screen.
class Breathing extends StatefulWidget {
  const Breathing({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
        scale: Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
        child: widget.child,
      );
}

/// A fat, colorful button with a thick darker bottom edge: obviously pressable.
/// Children's buttons carry no words; [label] is what screen readers say.
class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
    this.color = Colors.white,
    this.edge = const Color(0xFFE6DCCB),
    this.width,
    this.height = 76,
    this.radius,
    this.depth = 7,
    this.circle = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color edge;
  final double? width;
  final double height;
  final double? radius;
  final double depth;
  final bool circle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Pressable(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.only(bottom: depth),
            child: Container(
              width: width,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circle ? null : BorderRadius.circular(radius ?? height / 2),
                boxShadow: KidShadows.chunky(edge, depth),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// A white rounded square with an icon: back to the map, undo, close.
class NavButton extends StatelessWidget {
  const NavButton({super.key, required this.icon, required this.label, required this.onPressed, this.color = KidColors.ink});

  final String icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Pressable(
          onTap: onPressed,
          child: Container(
            width: KidTheme.navButton,
            height: KidTheme.navButton,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: KidShadows.soft(),
            ),
            child: KidIcon(icon, size: 30, color: color),
          ),
        ),
      ),
    );
  }
}

/// What a character says. The words are for grown-ups and screen readers;
/// children will hear them (voice comes in a later version).
class VoiceBubble extends StatelessWidget {
  const VoiceBubble(this.text, {super.key, this.fontSize = 17, this.maxWidth = 280});

  final String text;
  final double fontSize;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: KidShadows.soft()),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const KidIcon('sound', size: 20, color: KidColors.sky),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, height: 1.35)),
        ),
      ]),
    );
  }
}

/// Pops in with a little bounce, after [delay]; lets a screen's toys arrive
/// one by one instead of all at once.
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  static const _pop = Duration(milliseconds: 520);

  // The delay is the start of the animation's own timeline rather than a
  // timer, so nothing is left pending when the screen goes away early.
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.delay + _pop)..forward();
  late final double _start = widget.delay.inMicroseconds / (widget.delay + _pop).inMicroseconds;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = _start + (1 - _start) * 0.4;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _c, curve: Interval(_start, fade)),
      // Screen readers see the buttons straight away, not after the pop.
      alwaysIncludeSemantics: true,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _c, curve: Interval(_start, 1, curve: Curves.easeOutBack)),
        child: widget.child,
      ),
    );
  }
}

/// Three bouncing colored dots: "working on it", without words.
class BouncingDots extends StatefulWidget {
  const BouncingDots({super.key, this.colors = const [KidColors.coral, KidColors.sun, KidColors.sky]});

  final List<Color> colors;

  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.colors.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.translate(
                offset: Offset(0, -14 * math.max(0, math.sin((_c.value - i * 0.18) * 2 * math.pi))),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(color: widget.colors[i], shape: BoxShape.circle),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The small padlock in a corner that leads to the parent gate.
class ParentLockButton extends StatelessWidget {
  const ParentLockButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: Strings.parentMode,
      child: Semantics(
        button: true,
        label: Strings.parentMode,
        excludeSemantics: true,
        child: Pressable(
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
            child: const KidIcon('lock', size: 19, color: KidColors.inkSoft),
          ),
        ),
      ),
    );
  }
}

/// Warm postcard paper with faint dots.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child, this.color = KidColors.paper});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DotsPainter(color), child: child);
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final dot = Paint()..color = KidColors.paperDot;
    for (var y = 10.0; y < size.height; y += 20) {
      for (var x = 10.0; x < size.width; x += 20) {
        canvas.drawCircle(Offset(x, y), 1.4, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}

/// The white card a picture sits on, slightly tilted like a real postcard.
class PostcardFrame extends StatelessWidget {
  const PostcardFrame({super.key, required this.child, this.tilt = 0, this.padding = 12, this.radius = 22});

  final Widget child;
  final double tilt;
  final double padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: tilt * math.pi / 180,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius), boxShadow: KidShadows.soft()),
          child: child,
        ),
      );
}

/// The original photo as a postage stamp with perforated edges.
class PhotoStamp extends StatelessWidget {
  const PhotoStamp({super.key, required this.image, this.width = 76, this.height = 90, this.tilt = 7});

  final ImageProvider image;
  final double width;
  final double height;
  final double tilt;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Transform.rotate(
          angle: tilt * math.pi / 180,
          child: DecoratedBox(
            decoration: const BoxDecoration(boxShadow: [BoxShadow(color: Color(0x47284032), blurRadius: 8, offset: Offset(0, 6))]),
            child: ClipPath(
              clipper: _StampClipper(),
              child: Container(
                width: width,
                height: height,
                color: Colors.white,
                padding: const EdgeInsets.all(7),
                child: Image(image: image, fit: BoxFit.cover, gaplessPlayback: true),
              ),
            ),
          ),
        ),
      );
}

class _StampClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = 3.2, step = 8.0;
    final path = Path()..addRect(Offset.zero & size);
    final holes = Path();
    final nx = (size.width / step).round(), ny = (size.height / step).round();
    for (var i = 0; i < nx; i++) {
      final x = size.width / nx * (i + 0.5);
      holes.addOval(Rect.fromCircle(center: Offset(x, 0), radius: r));
      holes.addOval(Rect.fromCircle(center: Offset(x, size.height), radius: r));
    }
    for (var i = 0; i < ny; i++) {
      final y = size.height / ny * (i + 0.5);
      holes.addOval(Rect.fromCircle(center: Offset(0, y), radius: r));
      holes.addOval(Rect.fromCircle(center: Offset(size.width, y), radius: r));
    }
    return Path.combine(PathOperation.difference, path, holes);
  }

  @override
  bool shouldReclip(_StampClipper old) => false;
}

/// A round postmark with the date and wavy lines.
class Postmark extends StatelessWidget {
  const Postmark(this.text, {super.key, this.size = 58, this.color = const Color(0x9EB0561C)});

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Transform.rotate(
          angle: -0.25,
          child: CustomPaint(size: Size(size * 1.6, size), painter: _PostmarkPainter(text, color)),
        ),
      );
}

class _PostmarkPainter extends CustomPainter {
  _PostmarkPainter(this.text, this.color);

  final String text;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    final c = Offset(s / 2, s / 2);
    canvas.drawCircle(c, s / 2 - 2, paint);
    canvas.drawCircle(c, s / 2 - 8, paint..strokeWidth = 1.4);
    for (var i = 0; i < 3; i++) {
      final y = s * (0.36 + 0.14 * i);
      final wave = Path()..moveTo(s * 0.72, y);
      for (var k = 0; k < 3; k++) {
        final x = s * 0.72 + k * 16;
        wave.quadraticBezierTo(x + 4, y - 5, x + 8, y);
        wave.quadraticBezierTo(x + 12, y + 5, x + 16, y);
      }
      canvas.drawPath(wave, paint..strokeWidth = 2.2);
    }
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: s * 0.2, fontWeight: FontWeight.w700, fontFamily: KidTheme.font)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_PostmarkPainter old) => old.text != text || old.color != color;
}

/// A white chip with an icon and text (parents read these).
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.text, this.iconColor = const Color(0xFFE0702A), this.dashed = false});

  final String icon;
  final String text;
  final Color iconColor;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: dashed ? Border.all(color: const Color(0xFFE89A4C), width: 2) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          KidIcon(icon, size: 17, color: iconColor),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF8A4B12))),
        ]),
      );
}

String shortDate(DateTime d) => '${d.month}/${d.day}';
