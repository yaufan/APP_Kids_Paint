import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// The app's mascot: a little crayon with a face that bobs and waves.
/// Placeholder art until a designer draws the real character.
class CrayonBuddy extends StatefulWidget {
  const CrayonBuddy({super.key, this.height = 160, this.color = KidColors.tangerine});

  final double height;
  final Color color;

  @override
  State<CrayonBuddy> createState() => _CrayonBuddyState();
}

class _CrayonBuddyState extends State<CrayonBuddy> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.height * 0.75,
        height: widget.height,
        child: CustomPaint(painter: _BuddyPainter(_c, widget.color)),
      ),
    );
  }
}

class _BuddyPainter extends CustomPainter {
  _BuddyPainter(this.time, this.color) : super(repaint: time);

  final Animation<double> time;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final phase = time.value * 2 * math.pi;
    final bob = math.sin(phase) * h * 0.02;
    final ink = Paint()
      ..color = KidColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, w * 0.04)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Paint fill(Color c) => Paint()..color = c;
    final dark = Color.lerp(color, KidColors.ink, 0.25)!;

    canvas.save();
    canvas.translate(0, bob);

    final left = w * 0.22, right = w * 0.78, top = h * 0.3, bottom = h * 0.9;

    // Feet.
    for (final x in [w * 0.38, w * 0.62]) {
      final foot = Rect.fromCenter(center: Offset(x, bottom + h * 0.02), width: w * 0.2, height: h * 0.06);
      canvas.drawOval(foot, fill(dark));
      canvas.drawOval(foot, ink);
    }

    // Arms: the right one waves.
    final wave = math.sin(phase * 2) * 0.5;
    canvas.drawLine(Offset(left, h * 0.58), Offset(w * 0.06, h * 0.68), ink);
    final shoulder = Offset(right, h * 0.55);
    canvas.drawLine(shoulder, shoulder + Offset(math.cos(-1.0 + wave), math.sin(-1.0 + wave)) * w * 0.2, ink);

    // Tip.
    final tip = Path()
      ..moveTo(left + w * 0.04, top)
      ..lineTo(w * 0.5, h * 0.04)
      ..lineTo(right - w * 0.04, top)
      ..close();
    canvas.drawPath(tip, fill(dark));
    canvas.drawPath(tip, ink);

    // Body with a paper wrapper.
    final body = RRect.fromLTRBR(left, top, right, bottom, Radius.circular(w * 0.12));
    canvas.drawRRect(body, fill(color));
    final wrapper = Rect.fromLTRB(left, h * 0.66, right, h * 0.8);
    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(wrapper, fill(Colors.white.withValues(alpha: 0.55)));
    canvas.restore();
    canvas.drawLine(wrapper.topLeft, wrapper.topRight, ink..strokeWidth = ink.strokeWidth * 0.7);
    canvas.drawLine(wrapper.bottomLeft, wrapper.bottomRight, ink);
    ink.strokeWidth = math.max(2.5, w * 0.04);
    canvas.drawRRect(body, ink);

    // Face: blinks now and then.
    final blink = (time.value * 3 % 1) > 0.94;
    final eyeY = h * 0.45;
    for (final x in [w * 0.39, w * 0.61]) {
      if (blink) {
        canvas.drawLine(Offset(x - w * 0.04, eyeY), Offset(x + w * 0.04, eyeY), ink);
      } else {
        canvas.drawOval(Rect.fromCenter(center: Offset(x, eyeY), width: w * 0.09, height: h * 0.07), fill(KidColors.ink));
        canvas.drawCircle(Offset(x - w * 0.012, eyeY - h * 0.012), w * 0.017, fill(Colors.white));
      }
    }
    for (final x in [w * 0.31, w * 0.69]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, h * 0.52), width: w * 0.11, height: h * 0.035),
          fill(KidColors.blush));
    }
    canvas.drawArc(Rect.fromCenter(center: Offset(w * 0.5, h * 0.52), width: w * 0.18, height: h * 0.06), 0.2,
        math.pi - 0.4, false, ink);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BuddyPainter old) => old.color != color;
}
