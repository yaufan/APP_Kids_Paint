import 'package:flutter/material.dart';

/// 3D toy style: soft pastel daylight, white rounded toys with gentle
/// shadows, 3D illustrations. See docs/design.md.
abstract final class KidColors {
  static const paper = Color(0xFFFFF8EE);
  static const paperDeep = Color(0xFFFCEBD5);
  static const ink = Color(0xFF4A3B47);
  static const inkSoft = Color(0xFF8D7E8A);

  static const berry = Color(0xFFFF7FA3);
  static const sun = Color(0xFFFFC94D);
  static const sky = Color(0xFF5CC2FF);
  static const grass = Color(0xFF7DD87A);
  static const lavender = Color(0xFFB79CFF);
  static const tangerine = Color(0xFFFFA45C);

  static const skyTop = Color(0xFF9FDBFF);
  static const skyBottom = Color(0xFFE6F6FF);
  static const hillBack = Color(0xFFB4E59A);
  static const hillFront = Color(0xFF8ED47B);
  static const hillShade = Color(0xFF6FC069);
  static const blush = Color(0xFFFFA9BE);
}

/// Soft, layered shadows that make white shapes read as physical toys.
abstract final class KidShadows {
  static List<BoxShadow> toy([Color tint = const Color(0xFF6B4E71)]) => [
        BoxShadow(color: tint.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 10)),
        BoxShadow(color: tint.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2)),
      ];
}

abstract final class KidTheme {
  // Short names kept for call sites; see KidColors for the full palette.
  static const paper = KidColors.paper;
  static const sun = KidColors.sun;
  static const sky = KidColors.sky;
  static const grass = KidColors.grass;
  static const berry = KidColors.berry;
  static const ink = KidColors.ink;

  /// About 2 cm on a typical phone: twice a normal app button.
  static const bigButton = 124.0;
  static const toolButton = 76.0;

  /// jf open 粉圓 (OFL): a rounded typeface made in Taiwan.
  static const font = 'Huninn';

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: KidColors.berry, surface: KidColors.paper),
      scaffoldBackgroundColor: KidColors.paper,
      fontFamily: font,
      // Color emoji wherever the main font lacks them.
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
          side: BorderSide(color: KidColors.ink.withValues(alpha: 0.08)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: KidColors.ink, displayColor: KidColors.ink),
    );
  }
}
