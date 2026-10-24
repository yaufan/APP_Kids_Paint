import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'coloring.dart';

/// The palette as a box of real-looking crayons; the chosen one pops out.
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
    final box = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      boxShadow: KidShadows.toy(),
    );
    if (vertical) {
      return Container(
        padding: const EdgeInsets.fromLTRB(6, 12, 12, 12),
        decoration: box,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [for (final c in kidPalette) crayon(c)]),
        ),
      );
    }
    // Portrait: two rows of six, so every crayon is in view without scrolling.
    const perRow = 6;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: box,
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

  static const width = 44.0, length = 80.0, lift = 16.0;

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
              duration: const Duration(milliseconds: 260),
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

/// A crayon with rounded, shaded body, paper wrapper and a glossy tip.
class _CrayonPainter extends CustomPainter {
  _CrayonPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final isWhite = color.computeLuminance() > 0.9;
    final light = Color.lerp(color, Colors.white, 0.45)!;
    final dark = Color.lerp(color, Colors.black, isWhite ? 0.12 : 0.22)!;
    // Shading across the barrel: highlight on the left, shade on the right.
    Shader barrel(Rect r) => LinearGradient(colors: [light, color, color, dark], stops: const [0, 0.35, 0.65, 1])
        .createShader(r);

    final bodyRect = Rect.fromLTRB(w * 0.12, h * 0.3, w * 0.88, h * 0.98);
    final body = RRect.fromRectAndRadius(bodyRect, Radius.circular(w * 0.2));
    canvas.drawShadow(Path()..addRRect(body), const Color(0xFF6B4E71), 3, false);

    final tip = Path()
      ..moveTo(w * 0.18, h * 0.32)
      ..quadraticBezierTo(w * 0.4, h * 0.05, w * 0.5, h * 0.03)
      ..quadraticBezierTo(w * 0.6, h * 0.05, w * 0.82, h * 0.32)
      ..close();
    canvas.drawPath(tip, Paint()..shader = barrel(Rect.fromLTRB(w * 0.18, 0, w * 0.82, h * 0.32)));

    canvas.drawRRect(body, Paint()..shader = barrel(bodyRect));
    canvas.save();
    canvas.clipRRect(body);
    // Paper wrapper with two thin stripes.
    canvas.drawRect(Rect.fromLTRB(0, h * 0.52, w, h * 0.84), Paint()..color = Colors.white.withValues(alpha: 0.42));
    final stripe = Paint()..color = dark.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTRB(0, h * 0.6, w, h * 0.63), stripe);
    canvas.drawRect(Rect.fromLTRB(0, h * 0.73, w, h * 0.76), stripe);
    canvas.restore();
    if (isWhite) {
      // A white crayon needs a faint edge to show on the white tray.
      canvas.drawRRect(body, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.black.withValues(alpha: 0.12));
    }
    // Shine.
    canvas.drawLine(Offset(w * 0.3, h * 0.36), Offset(w * 0.3, h * 0.48),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.75)
          ..strokeWidth = math.max(2, w * 0.08)
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_CrayonPainter old) => old.color != color;
}
