import 'package:flutter/material.dart';

/// Look and feel for 2.5–5 year olds: warm colors, round shapes, huge targets.
abstract final class KidTheme {
  static const paper = Color(0xFFFFF8E7);
  static const sun = Color(0xFFFFC233);
  static const sky = Color(0xFF6EC6FF);
  static const grass = Color(0xFF8BD17C);
  static const berry = Color(0xFFFF7A9C);
  static const ink = Color(0xFF3B2F2F);

  /// About 2 cm on a typical phone: twice a normal app button.
  static const bigButton = 120.0;
  static const toolButton = 76.0;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: sun, surface: paper);
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.comfortable,
      appBarTheme: const AppBarTheme(backgroundColor: paper, foregroundColor: ink, centerTitle: true),
      textTheme: Typography.blackMountainView.apply(bodyColor: ink, displayColor: ink),
    );
  }
}
