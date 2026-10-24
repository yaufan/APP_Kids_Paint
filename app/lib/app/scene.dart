import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

const _outline = 3.0;

Paint _ink([double width = _outline]) => Paint()
  ..color = KidColors.ink
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

Paint _fill(Color color) => Paint()..color = color;

/// The home screen's picture-book scene: sky, a smiling sun, drifting
/// clouds, rolling hills and flowers. Purely decorative.
class SceneBackground extends StatefulWidget {
  const SceneBackground({super.key, this.child});

  final Widget? child;

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _time =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScenePainter(_time), child: widget.child ?? const SizedBox.expand());
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.time) : super(repaint: time);

  final Animation<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, unit = math.min(w, h);
    final t = time.value;

    // Sky fading into paper.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KidColors.skyTop, KidColors.paper],
          stops: [0.0, 0.75],
        ).createShader(Offset.zero & size),
    );

    _sun(canvas, Offset(w * 0.8, h * 0.11), unit * 0.085, t);

    // Clouds drift slowly across and wrap around.
    for (final (y, scale, speed, phase) in [
      (0.09, 1.0, 1.0, 0.1),
      (0.2, 0.75, 1.6, 0.55),
      (0.15, 0.6, 1.25, 0.85),
    ]) {
      final cw = unit * 0.34 * scale;
      final x = ((phase + t * speed) % 1.0) * (w + cw * 2) - cw;
      _cloud(canvas, Offset(x, h * y), cw);
    }

    _hill(canvas, size, top: 0.70, amplitude: 0.035, color: KidColors.hillBack, waves: 1.3, shift: 0.2);
    _hill(canvas, size, top: 0.80, amplitude: 0.03, color: KidColors.hillFront, waves: 1.0, shift: 0.65);

    final rng = math.Random(7);
    for (var i = 0; i < 9; i++) {
      final x = w * (0.06 + i * 0.11 + rng.nextDouble() * 0.04);
      final y = h * (0.86 + rng.nextDouble() * 0.1);
      _flower(canvas, Offset(x, y), unit * 0.022, i.isEven ? KidColors.berry : KidColors.sun);
    }
  }

  void _sun(Canvas canvas, Offset c, double r, double t) {
    final rays = Paint()
      ..color = KidColors.sun
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6 + t * 2 * math.pi;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * r * 1.3, c + dir * r * 1.65, rays);
    }
    canvas.drawCircle(c, r, _fill(KidColors.sun));
    canvas.drawCircle(c, r, _ink());
    // Face.
    canvas.drawCircle(c + Offset(-r * 0.32, -r * 0.1), r * 0.09, _fill(KidColors.ink));
    canvas.drawCircle(c + Offset(r * 0.32, -r * 0.1), r * 0.09, _fill(KidColors.ink));
    canvas.drawOval(Rect.fromCenter(center: c + Offset(-r * 0.55, r * 0.2), width: r * 0.3, height: r * 0.18),
        _fill(KidColors.blush));
    canvas.drawOval(Rect.fromCenter(center: c + Offset(r * 0.55, r * 0.2), width: r * 0.3, height: r * 0.18),
        _fill(KidColors.blush));
    canvas.drawArc(Rect.fromCenter(center: c + Offset(0, r * 0.12), width: r * 0.6, height: r * 0.5), 0.3,
        math.pi - 0.6, false, _ink(2.5));
  }

  void _cloud(Canvas canvas, Offset left, double width) {
    final r = width * 0.2;
    final puffs = [
      Rect.fromCircle(center: left + Offset(r * 1.2, 0), radius: r),
      Rect.fromCircle(center: left + Offset(r * 2.3, -r * 0.6), radius: r * 1.25),
      Rect.fromCircle(center: left + Offset(r * 3.6, -r * 0.1), radius: r * 1.05),
      Rect.fromLTRB(left.dx + r * 1.2, left.dy - r * 0.2, left.dx + r * 3.6, left.dy + r),
    ];
    var path = Path()..addOval(puffs[0]);
    for (final rect in puffs.skip(1)) {
      final next = Path();
      if (rect.width == rect.height) {
        next.addOval(rect);
      } else {
        next.addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
      }
      path = Path.combine(PathOperation.union, path, next);
    }
    canvas.drawPath(path, _fill(Colors.white));
    canvas.drawPath(path, _ink());
  }

  void _hill(Canvas canvas, Size size,
      {required double top, required double amplitude, required Color color, required double waves, required double shift}) {
    final w = size.width, h = size.height;
    final path = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 6) {
      path.lineTo(x, h * (top - amplitude * math.sin((x / w * waves + shift) * 2 * math.pi)));
    }
    path
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, _fill(color));
    canvas.drawPath(path, _ink());
  }

  void _flower(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawLine(c, c + Offset(0, r * 2.2), _ink(2.5));
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5 - math.pi / 2;
      final p = c + Offset(math.cos(a), math.sin(a)) * r * 0.9;
      canvas.drawCircle(p, r * 0.62, _fill(color));
      canvas.drawCircle(p, r * 0.62, _ink(2));
    }
    canvas.drawCircle(c, r * 0.5, _fill(KidColors.sun));
    canvas.drawCircle(c, r * 0.5, _ink(2));
  }

  @override
  bool shouldRepaint(_ScenePainter old) => false;
}

/// Warm paper with a faint dot grid and a few doodled stars in the corners.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _PaperPainter(), child: child);
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, _fill(KidColors.paper));
    final dot = _fill(KidColors.paperDot);
    for (var y = 14.0; y < size.height; y += 28) {
      for (var x = 14.0; x < size.width; x += 28) {
        canvas.drawCircle(Offset(x, y), 1.6, dot);
      }
    }
    final unit = math.min(size.width, size.height);
    _star(canvas, Offset(size.width - unit * 0.08, size.height - unit * 0.1), unit * 0.035, KidColors.sun);
    _star(canvas, Offset(unit * 0.07, size.height - unit * 0.18), unit * 0.025, KidColors.berry);
    _star(canvas, Offset(size.width - unit * 0.18, unit * 0.32), unit * 0.02, KidColors.sky);
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5 - math.pi / 2;
      final rr = i.isEven ? r : r * 0.45;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, _fill(color));
    canvas.drawPath(path, _ink(2.5));
  }

  @override
  bool shouldRepaint(_PaperPainter old) => false;
}
