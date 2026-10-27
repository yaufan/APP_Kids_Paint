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
    case Motion.drive:
      // A steady drive with a little bump now and then.
      final w = pacing(48);
      final bump = math.max(0.0, math.sin(t * 5 * pace + wobble) - 0.85) * 20;
      return (at: Offset(w.x, laneY() - bump), left: w.left, tilt: 0.0, squash: 1.0);
    case Motion.rail:
      final w = pacing(58);
      return (at: Offset(w.x, area.bottom - 1.2 * math.sin(t * 14).abs()), left: w.left, tilt: 0.0, squash: 1.0);
    case Motion.fly:
      final w = pacing(56);
      final glide = t * 0.8 * pace + wobble;
      // Wings beat: a quick squash, and a slow rise and fall.
      return (at: Offset(w.x, laneY(40) + 40 * math.sin(glide)), left: w.left, tilt: 0.06 * math.cos(glide), squash: 1 + 0.08 * math.sin(t * 9));
    case Motion.sway:
      // Rooted where it grows, rocking in the breeze.
      final breeze = t * 1.3 * pace + wobble;
      return (at: Offset(area.left + area.width * phase, laneY()), left: false, tilt: 0.06 * math.sin(breeze), squash: 1 + 0.02 * math.sin(2 * breeze));
    case Motion.drift:
      // No up or down in space: a slow wander every way, turning round and round.
      final x = area.left + area.width * (0.5 + 0.45 * math.sin(t * 0.07 * pace + phase * 2 * math.pi));
      final y = area.top + area.height * (0.5 + 0.45 * math.sin(t * 0.11 * pace + wobble));
      return (at: Offset(x, y), left: false, tilt: 0.35 * math.sin(t * 0.25 * pace + wobble), squash: 1.0);
    case Motion.slide:
      // Waddles along, then drops onto its belly and slides, then stands up.
      final cycle = (t * 0.12 * pace + phase) % 1;
      final sliding = cycle > 0.62 && cycle < 0.86;
      final w = pacing(sliding ? 30 : 22);
      final waddle = math.sin(t * 9 * pace + wobble);
      return (
        at: Offset(w.x, laneY()),
        left: w.left,
        tilt: sliding ? (w.left ? -1.25 : 1.25) : 0.12 * waddle,
        squash: sliding ? 0.92 : 1.0,
      );
    case Motion.shelf:
      // On its spot on the shelf ([shelfSpots]), now and then a little wiggle.
      final wiggle = math.max(0.0, math.sin(t * 0.9 * pace + wobble) - 0.9) * 10;
      return (at: area.bottomCenter, left: false, tilt: 0.05 * wiggle * math.sin(t * 12), squash: 1.0);
  }
}

/// The shop's shelves: where their tops are in the scene (docs/design/v3/src
/// creatures.py SHOP_BOARDS), the lowest first.
const shopBoards = [840.0, 670.0, 500.0];

/// The night market's long table, the stalls' counters and their shelves
/// (creatures.py MARKET_COUNTERS), the lowest first.
const marketCounters = [800.0, 620.0, 460.0];

/// The night market's lanterns (creatures.py MARKET_LANTERNS), in scene units.
final marketLanterns = [for (var x = 40; x < 1000; x += 92) Offset(x.toDouble(), (150 + 50 * (1 - math.pow((x - 500) / 520, 2))).roundToDouble() + 14)];

/// Spots on the shelves (the tops of [boards]) that [view] shows clear of
/// the buttons: the bottom middle of each of the goods, side by side, the
/// lowest shelf first. The newest goods take the first spots. Goods keep
/// their full size on a phone too (unlike the creatures that roam): the
/// shelves hold them.
List<Offset> shelfSpots(SceneView view, {List<double> boards = shopBoards, double top = 110}) {
  final v = view.visible;
  const slot = 130.0, tallest = 150.0;
  final across = math.max(1, ((v.width - 30) / slot).floor());
  final left = v.left + (v.width - across * slot) / 2;
  return [
    for (final board in boards)
      if (board - tallest >= v.top + top / view.scale)
        for (var i = 0; i < across; i++) Offset(left + slot * (i + 0.5), board),
  ];
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
    // The polar sea's orcas keep to the water between the floes; the night
    // market's goldfish to their pool.
    Motion.swim when creature.habitat == Habitat.polar => (560.0, 690.0),
    Motion.swim when creature.habitat == Habitat.nightMarket => (930.0, 962.0),
    Motion.walk || Motion.hop => (640.0, 950.0),
    Motion.swim => (330.0, 800.0),
    Motion.float => (300.0, 760.0),
    Motion.crawl => (930.0, 950.0),
    Motion.fly => (260.0, 520.0),
    Motion.drive => (790.0, 930.0),
    Motion.rail => (648.0, 648.0),
    Motion.sway => (720.0, 950.0),
    Motion.shelf => (shopBoards.first, shopBoards.first), // see [shelfSpots]
    Motion.drift => (260.0, 760.0),
    Motion.slide => (730.0, 950.0),
  };
  // Swimmers and floaters are drawn up from their bottom, so leave room above.
  final y0 = math.max(lo, minY + creature.size * view.creatureScale * 0.7);
  final y1 = math.max(y0, math.min(hi, maxY));
  final x0 = v.left + half, x1 = math.max(v.left + half, v.right - half);
  return Rect.fromLTRB(x0, y0, x1, y1);
}
