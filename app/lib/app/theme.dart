import 'package:flutter/material.dart';

/// Picture-book sticker style: warm paper, candy colors, thick ink outlines.
abstract final class KidColors {
  static const paper = Color(0xFFFFF6E5);
  static const paperDot = Color(0x14000000);
  static const ink = Color(0xFF3D2C2E);
  static const berry = Color(0xFFFF6F91);
  static const sun = Color(0xFFFFC93C);
  static const sky = Color(0xFF4FB8F5);
  static const grass = Color(0xFF6CCB6A);
  static const lavender = Color(0xFFAE8CF5);
  static const tangerine = Color(0xFFFF9F45);
  static const skyTop = Color(0xFFAEE3FF);
  static const hillBack = Color(0xFFA9DE8C);
  static const hillFront = Color(0xFF82CC6E);
  static const tray = Color(0xFFF6DDB0);
  static const blush = Color(0xFFFF9EB5);
}

abstract final class KidTheme {
  // Kept for existing call sites; see KidColors for the full palette.
  static const paper = KidColors.paper;
  static const sun = KidColors.sun;
  static const sky = KidColors.sky;
  static const grass = KidColors.grass;
  static const berry = KidColors.berry;
  static const ink = KidColors.ink;

  /// About 2 cm on a typical phone: twice a normal app button.
  static const bigButton = 124.0;
  static const toolButton = 72.0;

  /// Thickness of every outline and the depth of sticker shadows.
  static const outline = 4.0;
  static const depth = 6.0;

  /// jf open 粉圓 (OFL): a rounded typeface made in Taiwan.
  static const font = 'Huninn';

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: KidColors.berry, surface: KidColors.paper),
      scaffoldBackgroundColor: KidColors.paper,
      fontFamily: font,
      // Color emoji for the animal avatars wherever the main font lacks them.
      fontFamilyFallback: const ['Noto Color Emoji'],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.comfortable,
      appBarTheme: const AppBarTheme(
        backgroundColor: KidColors.paper,
        foregroundColor: KidColors.ink,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: KidColors.ink, width: 2),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KidColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: KidColors.ink, width: 3),
        ),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: KidColors.ink, displayColor: KidColors.ink),
    );
  }
}
