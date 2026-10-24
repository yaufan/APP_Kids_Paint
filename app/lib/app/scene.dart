import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art.dart';
import 'theme.dart';

/// The home screen's picture-book world: a soft sky, a smiling sun, drifting
/// clouds, a rainbow and rolling hills with trees and flowers. Decorative.
class SceneBackground extends StatefulWidget {
  const SceneBackground({super.key, required this.child});

  final Widget child;

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _time =
      AnimationController(vsync: this, duration: const Duration(seconds: 50))..repeat();

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight, unit = math.min(w, h);
      Widget at(double x, double y, String art, double size) =>
          Positioned(left: x * w - size / 2, top: y * h - size / 2, child: ArtImage(art, size: size));

      return Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _SkyPainter())),
          // Rainbow peeking over the back hill.
          Positioned(left: -unit * 0.08, top: h * 0.56 - unit * 0.42, child: Opacity(
            opacity: 0.85,
            child: ArtImage(Art.rainbow, size: unit * 0.5),
          )),
          AnimatedBuilder(
            animation: _time,
            builder: (context, _) {
              final t = _time.value;
              final bob = math.sin(t * 2 * math.pi * 6) * unit * 0.008;
              return Stack(children: [
                // The sun bobs gently in the top right corner.
                Positioned(
                  right: unit * 0.05,
                  top: unit * 0.04 + bob,
                  child: ArtImage(Art.sun, size: unit * 0.24),
                ),
                for (final (y, size, speed, phase) in [
                  (0.08, 0.26, 1.0, 0.15),
                  (0.2, 0.2, 1.5, 0.6),
                  (0.14, 0.16, 1.25, 0.9),
                ])
                  Positioned(
                    left: ((phase + t * speed) % 1.0) * (w + unit * size * 2) - unit * size * 2,
                    top: h * y,
                    child: Opacity(opacity: 0.95, child: ArtImage(Art.cloud, size: unit * size)),
                  ),
              ]);
            },
          ),
          const Positioned.fill(child: CustomPaint(painter: _HillsPainter())),
          at(0.86, 0.66, Art.tree, unit * 0.22),
          at(0.73, 0.70, Art.tree, unit * 0.15),
          at(0.10, 0.84, Art.tulip, unit * 0.09),
          at(0.30, 0.90, Art.blossom, unit * 0.08),
          at(0.62, 0.88, Art.sunflower, unit * 0.11),
          at(0.84, 0.92, Art.tulip, unit * 0.08),
          at(0.47, 0.95, Art.blossom, unit * 0.06),
          Positioned.fill(child: widget.child),
        ],
      );
    });
  }
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [KidColors.skyTop, KidColors.skyBottom, KidColors.paper],
          stops: [0, 0.55, 0.8],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}

/// Two soft hills with a light rim along the top, like rounded clay.
class _HillsPainter extends CustomPainter {
  const _HillsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _hill(canvas, size, top: 0.66, amplitude: 0.04, waves: 1.2, shift: 0.15,
        colors: const [KidColors.hillBack, Color(0xFF9DDA86)]);
    _hill(canvas, size, top: 0.78, amplitude: 0.035, waves: 0.9, shift: 0.6,
        colors: const [KidColors.hillFront, KidColors.hillShade]);
  }

  void _hill(Canvas canvas, Size size,
      {required double top, required double amplitude, required double waves, required double shift, required List<Color> colors}) {
    final w = size.width, h = size.height;
    final path = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w + 6; x += 6) {
      path.lineTo(x, h * (top - amplitude * math.sin((x / w * waves + shift) * 2 * math.pi)));
    }
    path
      ..lineTo(w, h)
      ..close();
    final bounds = Rect.fromLTRB(0, h * (top - amplitude), w, h);
    canvas.drawShadow(path, const Color(0xFF3E7A3A), 8, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors)
            .createShader(bounds),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(_HillsPainter old) => false;
}

/// Warm paper with a soft glow and fine speckles, for every other screen.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: const _PaperPainter(), child: child);
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.6, -0.8),
          radius: 1.4,
          colors: [Colors.white, KidColors.paper, KidColors.paperDeep],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    // Paper grain: a fixed scatter of faint specks.
    final rng = math.Random(3);
    final speck = Paint()..color = const Color(0xFF8A6A4A).withValues(alpha: 0.06);
    final count = (size.width * size.height / 900).round();
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          0.6 + rng.nextDouble() * 1.1, speck);
    }
  }

  @override
  bool shouldRepaint(_PaperPainter old) => false;
}
