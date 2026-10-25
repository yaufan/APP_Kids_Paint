import 'package:flutter/material.dart';

/// 畫畫小鎮 (design v3): saturated, friendly colors on a warm postcard paper.
/// See docs/design-v3.md.
abstract final class KidColors {
  static const coral = Color(0xFFFF5E5B);
  static const coralDark = Color(0xFFD9423F);
  static const sun = Color(0xFFFFC94A);
  static const sunDark = Color(0xFFE0A21C);
  static const sky = Color(0xFF4DA8FF);
  static const skyDark = Color(0xFF2C7FD6);
  static const grass = Color(0xFF6BCB77);
  static const grassDark = Color(0xFF3FA052);
  static const teal = Color(0xFF2EC4B6);
  static const grape = Color(0xFF8C6CFF);
  static const pink = Color(0xFFFF8FB1);

  /// Postcard paper: children's screens.
  static const paper = Color(0xFFFFF8EC);
  static const paperDot = Color(0xFFF0E2C8);

  /// Parent screens.
  static const parentBg = Color(0xFFF7F5F0);
  static const line = Color(0xFFEFEAE0);

  static const ink = Color(0xFF34413A);
  static const inkSoft = Color(0xFF6B7A70);
  static const night = Color(0xFF2B2490);
}

/// Soft shadows that make white shapes read as things you can pick up.
abstract final class KidShadows {
  static List<BoxShadow> soft([Color tint = const Color(0xFF1E3C28)]) => [
        BoxShadow(color: tint.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 8)),
      ];

  /// The thick bottom edge of a chunky button, plus a soft glow.
  static List<BoxShadow> chunky(Color edge, [double depth = 7]) => [
        BoxShadow(color: edge, offset: Offset(0, depth)),
        BoxShadow(color: edge.withValues(alpha: 0.35), blurRadius: 22, offset: Offset(0, depth + 8)),
      ];
}

abstract final class KidTheme {
  /// The camera button on the map: the biggest thing on screen.
  static const cameraButton = 124.0;
  static const toolButton = 62.0;
  static const navButton = 56.0;

  /// jf open 粉圓 (OFL): a rounded typeface made in Taiwan.
  static const font = 'Huninn';

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: KidColors.coral, surface: KidColors.paper),
      scaffoldBackgroundColor: KidColors.paper,
      fontFamily: font,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.comfortable,
      appBarTheme: const AppBarTheme(
        backgroundColor: KidColors.parentBg,
        foregroundColor: KidColors.ink,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? KidColors.grass : const Color(0xFFD6D9D4)),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: KidColors.ink, displayColor: KidColors.ink),
    );
  }
}
