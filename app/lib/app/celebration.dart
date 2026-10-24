import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'art.dart';
import 'theme.dart';

/// A short "well done!" moment when a child finishes a picture: confetti
/// bursts up and floats down while a party popper and a star pop in.
class Celebration extends StatefulWidget {
  const Celebration({super.key});

  static const duration = Duration(milliseconds: 1800);

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Celebration.duration)..forward();
  final _pieces = _Confetti.burst(90, math.Random());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final pop = Curves.elasticOut.transform((t / 0.45).clamp(0.0, 1.0));
          final fade = 1 - Curves.easeIn.transform(((t - 0.75) / 0.25).clamp(0.0, 1.0));
          return Opacity(
            opacity: fade,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: Colors.white.withValues(alpha: 0.35 * (1 - t)))),
                Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(_pieces, t))),
                Center(
                  child: Transform.scale(
                    scale: pop,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Transform.rotate(angle: -0.2, child: const ArtImage(Art.party, size: 150)),
                      const SizedBox(width: 12),
                      Transform.rotate(angle: 0.15 + t * 0.6, child: const ArtImage(Art.star, size: 120)),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Confetti {
  _Confetti(this.x, this.vx, this.vy, this.spin, this.size, this.color);

  final double x, vx, vy, spin, size;
  final Color color;

  static const _colors = [
    KidColors.berry, KidColors.sun, KidColors.sky, KidColors.grass, KidColors.lavender, KidColors.tangerine,
  ];

  /// Pieces shot up from the bottom center, fanning out.
  static List<_Confetti> burst(int n, math.Random r) => [
        for (var i = 0; i < n; i++)
          _Confetti(
            0.5 + (r.nextDouble() - 0.5) * 0.2,
            (r.nextDouble() - 0.5) * 1.3,
            1.2 + r.nextDouble() * 0.9,
            (r.nextDouble() - 0.5) * 20,
            6 + r.nextDouble() * 8,
            _colors[r.nextInt(_colors.length)],
          ),
      ];
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t);

  final List<_Confetti> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const gravity = 2.4;
    for (final p in pieces) {
      final x = (p.x + p.vx * t * 0.6) * size.width;
      final y = size.height * (1.05 - (p.vy * t - gravity * t * t * 0.5));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(2)),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
