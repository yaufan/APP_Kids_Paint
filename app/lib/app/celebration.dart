import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Confetti shot up from the bottom that floats down and fades: the "well
/// done!" moment when a postcard is sent or a new place is built.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.duration = const Duration(milliseconds: 2200), this.pieces = 90});

  final Duration duration;
  final int pieces;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)..forward();
  late final _pieces = _Piece.burst(widget.pieces, math.Random());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Opacity(
            opacity: 1 - Curves.easeIn.transform(((_c.value - 0.75) / 0.25).clamp(0.0, 1.0)),
            child: CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, _c.value)),
          ),
        ),
      );
}

class _Piece {
  _Piece(this.x, this.vx, this.vy, this.spin, this.size, this.color);

  final double x, vx, vy, spin, size;
  final Color color;

  static const _colors = [
    KidColors.coral, KidColors.sun, KidColors.sky, KidColors.grass, KidColors.grape, KidColors.pink, KidColors.teal,
  ];

  /// Pieces shot up from the bottom center, fanning out.
  static List<_Piece> burst(int n, math.Random r) => [
        for (var i = 0; i < n; i++)
          _Piece(
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

  final List<_Piece> pieces;
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
