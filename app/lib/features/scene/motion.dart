import 'dart:math' as math;
import 'dart:ui';

import '../../core/creatures.dart';

/// Where a creature is at a moment: the bottom middle of its picture in
/// scene units, whether it faces left (pictures face right), a tilt in
/// radians and a vertical squash.
typedef Pose = ({Offset at, bool left, double tilt, double squash});

/// The creature's pose at [t] seconds, moving inside [area] (scene units;
/// where the bottom middle of the picture may go). [seed] (the artwork's id)
/// gives every creature its own lane, starting point and speed; consecutive
/// seeds are spread far apart so neighbors do not walk on top of each other.
Pose poseAt(Motion motion, double t, int seed, Rect area) {
  final rand = math.Random(seed * 7919);
  final lane = (seed * 0.6180339887 + 0.13) % 1;
  final phase = (seed * 0.7548776662 + 0.29) % 1;
  final pace = 0.7 + rand.nextDouble() * 0.6;
  final wobble = rand.nextDouble() * 2 * math.pi;

  // Back and forth across the area at [speed] units a second.
  ({double x, bool left}) pacing(double speed) {
    final span = math.max(area.width, 1.0);
    final p = (phase * 2 * span + speed * pace * t) % (2 * span);
    return p < span ? (x: area.left + p, left: false) : (x: area.left + 2 * span - p, left: true);
  }

  double laneY([double margin = 0]) {
    final m = math.min(margin, area.height / 2);
    return area.top + m + (area.height - 2 * m) * lane;
  }

  switch (motion) {
    case Motion.walk:
      final w = pacing(30);
      final step = math.sin(t * 7 * pace + wobble);
      return (at: Offset(w.x, laneY() - 5 * step.abs()), left: w.left, tilt: 0.03 * step, squash: 1.0);
    case Motion.hop:
      final w = pacing(26);
      final hop = math.sin(t * math.pi * 1.4 * pace + wobble).abs();
      return (at: Offset(w.x, laneY() - 40 * hop), left: w.left, tilt: 0.0, squash: 1 - 0.06 * (1 - hop));
    case Motion.swim:
      final w = pacing(44);
      final wave = t * 1.1 * pace + wobble;
      return (at: Offset(w.x, laneY(30) + 26 * math.sin(wave)), left: w.left, tilt: 0.1 * math.cos(wave) * (w.left ? -1 : 1), squash: 1.0);
    case Motion.float:
      final x = area.left + area.width * (0.5 + 0.45 * math.sin(t * 0.09 * pace + phase * 2 * math.pi));
      final y = laneY(60) + 60 * math.sin(t * 0.7 * pace + wobble);
      return (at: Offset(x, y), left: false, tilt: 0.04 * math.sin(t * 0.9 + wobble), squash: 1 + 0.06 * math.sin(t * 2.6 * pace + wobble));
    case Motion.crawl:
      final w = pacing(32);
      return (at: Offset(w.x, area.bottom), left: false, tilt: 0.07 * math.sin(t * 9 * pace + wobble), squash: 1.0);
  }
}

/// How a 1000 x 1000 scene sits on a screen: covering it, anchored at the
/// bottom, so phones see its middle and wide screens its lower part.
class SceneView {
  SceneView(this.screen) : scale = math.max(screen.width / 1000, screen.height / 1000);

  final Size screen;
  final double scale;

  Offset get origin => Offset((screen.width - 1000 * scale) / 2, screen.height - 1000 * scale);

  /// The part of the scene on screen, in scene units.
  Rect get visible => Rect.fromLTWH(-origin.dx / scale, -origin.dy / scale, screen.width / scale, screen.height / scale);

  Offset toScreen(Offset scene) => origin + scene * scale;

  /// Creatures are drawn smaller when little of the scene fits across (a
  /// phone), so a full zoo does not pile up.
  double get creatureScale => (visible.width / 700).clamp(0.7, 1.0);
}

/// Where [creature] may go on [view] (the bottom middle of its picture),
/// clear of the buttons at the top ([top] px) and bottom ([bottom] px).
Rect roamArea(Creature creature, SceneView view, {double top = 110, double bottom = 30}) {
  final v = view.visible;
  final half = creature.size * view.creatureScale / 2 + 12;
  final minY = v.top + top / view.scale;
  final maxY = v.bottom - bottom / view.scale;
  final (lo, hi) = switch (creature.motion) {
    Motion.walk || Motion.hop => (640.0, 950.0),
    Motion.swim => (330.0, 800.0),
    Motion.float => (300.0, 760.0),
    Motion.crawl => (930.0, 950.0),
  };
  // Swimmers and floaters are drawn up from their bottom, so leave room above.
  final y0 = math.max(lo, minY + creature.size * view.creatureScale * 0.7);
  final y1 = math.max(y0, math.min(hi, maxY));
  final x0 = v.left + half, x1 = math.max(v.left + half, v.right - half);
  return Rect.fromLTRB(x0, y0, x1, y1);
}
