import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'coloring.dart';

/// The palette as a tray of real-looking crayons; the chosen one pops out.
class CrayonTray extends StatelessWidget {
  const CrayonTray({super.key, required this.selected, required this.onSelect, this.vertical = false});

  final int selected;
  final ValueChanged<int> onSelect;

  /// Crayons stacked top to bottom, pointing left (landscape layout).
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    Widget crayon(int c) => _Crayon(
          key: ValueKey('swatch-$c'),
          color: c,
          selected: c == selected,
          vertical: vertical,
          onTap: () => onSelect(c),
        );
    final tray = BoxDecoration(
      color: KidColors.tray,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: KidColors.ink, width: 3),
      boxShadow: const [BoxShadow(color: KidColors.ink, offset: Offset(0, KidTheme.depth))],
    );
    if (vertical) {
      return Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: tray,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [for (final c in kidPalette) crayon(c)]),
        ),
      );
    }
    // Portrait: two rows of six, so every crayon is in view without scrolling.
    const perRow = 6;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      decoration: tray,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row * perRow < kidPalette.length; row++)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final c in kidPalette.skip(row * perRow).take(perRow)) crayon(c)],
            ),
        ],
      ),
    );
  }
}

class _Crayon extends StatelessWidget {
  const _Crayon({super.key, required this.color, required this.selected, required this.vertical, required this.onTap});

  final int color;
  final bool selected;
  final bool vertical;
  final VoidCallback onTap;

  static const width = 44.0, length = 78.0, lift = 14.0;

  @override
  Widget build(BuildContext context) {
    final crayon = CustomPaint(size: const Size(width, length), painter: _CrayonPainter(Color(color)));
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: vertical ? const EdgeInsets.symmetric(vertical: 2) : const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(
            width: vertical ? length + lift : width,
            height: vertical ? width : length + lift,
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              alignment: vertical
                  ? (selected ? Alignment.centerLeft : Alignment.centerRight)
                  : (selected ? Alignment.topCenter : Alignment.bottomCenter),
              child: vertical ? RotatedBox(quarterTurns: 3, child: crayon) : crayon,
            ),
          ),
        ),
      ),
    );
  }
}

class _CrayonPainter extends CustomPainter {
  _CrayonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ink = Paint()
      ..color = KidColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final dark = Color.lerp(color, KidColors.ink, color == const Color(0xFFFFFFFF) ? 0.08 : 0.2)!;

    final tip = Path()
      ..moveTo(w * 0.2, h * 0.3)
      ..quadraticBezierTo(w * 0.42, h * 0.04, w * 0.5, h * 0.03)
      ..quadraticBezierTo(w * 0.58, h * 0.04, w * 0.8, h * 0.3)
      ..close();
    canvas.drawPath(tip, Paint()..color = dark);
    canvas.drawPath(tip, ink);

    final body = RRect.fromLTRBR(w * 0.1, h * 0.28, w * 0.9, h * 0.99, const Radius.circular(8));
    canvas.drawRRect(body, Paint()..color = color);
    canvas.save();
    canvas.clipRRect(body);
    // Paper wrapper with two stripes.
    canvas.drawRect(Rect.fromLTRB(0, h * 0.5, w, h * 0.84), Paint()..color = Colors.white.withValues(alpha: 0.5));
    canvas.drawRect(Rect.fromLTRB(0, h * 0.58, w, h * 0.62), Paint()..color = dark);
    canvas.drawRect(Rect.fromLTRB(0, h * 0.72, w, h * 0.76), Paint()..color = dark);
    canvas.restore();
    canvas.drawRRect(body, ink);
    // Shine.
    canvas.drawLine(Offset(w * 0.28, h * 0.36), Offset(w * 0.28, h * 0.46),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..strokeWidth = math.max(2, w * 0.08)
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_CrayonPainter old) => old.color != color;
}
