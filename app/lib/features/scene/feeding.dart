import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../../core/creatures.dart';
import 'motion.dart';

/// The food in a place where animals live (0.19), and the animals coming
/// to eat it. Tap the food: it fills up, the nearest animals walk (hop,
/// swim, fly) over, eat it up, say it was yummy and go back to what they
/// were doing. Plants, vehicles and the snowman do not come.

/// Where the food stands (its bottom middle, scene units), how wide it is,
/// and what it is (for a screen reader).
typedef Feeder = ({Offset at, double width, String food});

/// On the ground in front, left of the big draw button: a phone and a
/// tablet both show it there (docs/design/v5/feeders.py draws them).
const feeders = <Habitat, Feeder>{
  Habitat.zoo: (at: Offset(410, 930), width: 150, food: '水果'),
  Habitat.aquarium: (at: Offset(410, 955), width: 150, food: '飼料'),
  Habitat.dinoPark: (at: Offset(420, 930), width: 150, food: '葉子'),
  Habitat.insects: (at: Offset(420, 935), width: 150, food: '西瓜'),
  Habitat.polar: (at: Offset(420, 935), width: 150, food: '魚'),
  Habitat.farm: (at: Offset(470, 940), width: 150, food: '牧草'),
};

/// The pictures are 300 x 240 with the rim 150 from the top: the food
/// stands on the rim and sinks into the container as it is eaten.
const feederAspect = 240 / 300, feederRim = 150 / 240;

/// Animals that get about can come and eat.
bool eats(Creature creature) => feeders.containsKey(creature.habitat) && _comers.contains(creature.motion);

const _comers = {Motion.walk, Motion.hop, Motion.crawl, Motion.slide, Motion.swim, Motion.float, Motion.fly};
const _ground = {Motion.walk, Motion.hop, Motion.crawl, Motion.slide};

/// Scene units a second on the way to the food: snails and crabs take their time.
double _speed(Motion motion) => switch (motion) {
      Motion.crawl => 90,
      Motion.float => 120,
      Motion.hop || Motion.slide => 150,
      Motion.fly => 200,
      _ => 165,
    };

/// One animal at the meal.
class Eater {
  Eater({required this.id, required this.creature, required this.spot, required this.facesLeft, required this.delay, required this.go});

  /// The artwork.
  final int id;
  final Creature creature;

  /// Where it eats (scene units), and whether it faces left to look at the food.
  final Offset spot;
  final bool facesLeft;

  /// Seconds after the food goes out that it sets off, and the seconds it
  /// takes to get there.
  final double delay, go;

  double get arrive => delay + go;
  double get full => arrive + Meal.eating;
  double get home => full + Meal.back;

  /// Its pose [s] seconds into the meal: [natural] is where it would be
  /// now, [from] where it was when it set off.
  Pose pose(double s, {required Pose natural, required Pose from}) {
    if (s < delay || s >= home) return natural;
    final motion = creature.motion;
    final ground = _ground.contains(motion);
    if (s < arrive) {
      final u = (s - delay) / go, e = Curves.easeInOut.transform(u);
      final at = Offset.lerp(from.at, spot, e)!;
      final lift = switch (motion) {
        Motion.hop => 34 * math.sin(math.pi * (u * go * 1.6 % 1)).abs(),
        Motion.walk || Motion.slide => 6 * math.sin(s * 14).abs(),
        Motion.crawl => 0.0,
        _ => 10 * math.sin(s * 5),
      };
      final heading = spot.dx < from.at.dx;
      return (at: at - Offset(0, lift), left: heading, tilt: ground ? 0.04 * math.sin(s * 14) : 0.05 * math.cos(s * 5), squash: 1.0);
    }
    if (s < full) {
      // Head down to the food and up again, bite after bite.
      final k = s - arrive;
      final nibble = 0.5 + 0.5 * math.sin(k * 9 - math.pi / 2);
      final hover = ground ? 0.0 : 8 * math.sin(k * 4);
      return (at: spot - Offset(0, hover), left: facesLeft, tilt: 0.13 * nibble, squash: 1 - 0.04 * nibble);
    }
    // Back to where it would have been by now, easing into its own way of moving.
    final e = Curves.easeInOut.transform((s - full) / Meal.back);
    return (
      at: Offset.lerp(spot, natural.at, e)!,
      left: e < 0.5 ? natural.at.dx < spot.dx : natural.left,
      tilt: natural.tilt * e,
      squash: 1 + (natural.squash - 1) * e,
    );
  }
}

/// The food put out at [start] (seconds on the scene's clock) and who comes.
class Meal {
  Meal({required this.start, required this.feeder, required this.eaters, required this.wasLeft});

  final double start;
  final Feeder feeder;
  final List<Eater> eaters;

  /// How full the food was before it was filled up.
  final double wasLeft;

  /// Seconds: the food popping up, eating, going back.
  static const fill = 0.45, eating = 3.2, back = 1.4;

  /// What is left once they are done (a few crumbs).
  static const leftover = 0.12;

  /// Seconds from [start] to the last one back.
  double get length => eaters.fold(fill, (m, e) => math.max(m, e.home));

  Eater? eater(int id) {
    for (final e in eaters) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// How full the food is [s] seconds into the meal: it pops up full, then
  /// goes down while they eat.
  double level(double s) {
    if (s < fill) return wasLeft + (1 - wasLeft) * Curves.elasticOut.transform((s / fill).clamp(0.0, 1.0));
    if (eaters.isEmpty) return 1;
    final first = eaters.map((e) => e.arrive).reduce(math.min), last = eaters.map((e) => e.full).reduce(math.max);
    return 1 - (1 - leftover) * ((s - first) / (last - first)).clamp(0.0, 1.0);
  }

  /// Food goes out at [now] for the animals [around] (each with where it
  /// is now and where it may go): the nearest that eat come, as many as
  /// fit around the food on [view] (three on a phone, four wider). Those
  /// coming from the right eat on the right; the nearest stand beside the
  /// food, the next ones a little behind it. Nobody eats under [avoid]
  /// (the big draw button, in scene units) while another place is free.
  static Meal plan({
    required double now,
    required Feeder feeder,
    required List<({int id, Creature creature, Pose pose, Rect area})> around,
    required SceneView view,
    double wasLeft = 1,
    Rect? avoid,
  }) {
    final f = feeder.at, fw = feeder.width * view.creatureScale;
    final most = view.visible.width < 700 ? 3 : 4;
    final coming = [for (final a in around) if (eats(a.creature)) a]
      ..sort((a, b) => (a.pose.at - f).distance.compareTo((b.pose.at - f).distance));
    final taken = <(bool, bool)>{}; // (on the right, behind)
    final eaters = <Eater>[];
    final v = view.visible;
    for (final a in coming.take(most)) {
      final w = a.creature.size * view.creatureScale;
      Offset spotAt((bool, bool) slot) {
        final (right, behind) = slot;
        final side = right ? 1.0 : -1.0;
        var spot = switch ((_ground.contains(a.creature.motion), behind)) {
          (true, true) => Offset(f.dx + side * (fw * 0.22 + w * 0.3), f.dy - 50),
          (true, false) => Offset(f.dx + side * (fw * 0.42 + w * 0.42), f.dy + 4),
          (false, _) => Offset(f.dx + side * (fw * 0.28 + w * 0.22), f.dy - fw * feederAspect * 0.75 - (behind ? 60 : 0)),
        };
        // The polar sea's orcas and narwhals keep to the water.
        if (a.creature.motion == Motion.swim && a.creature.habitat == Habitat.polar) spot = Offset(spot.dx, a.area.bottom);
        return Offset(spot.dx.clamp(v.left + w / 2, math.max(v.left + w / 2, v.right - w / 2)).toDouble(), spot.dy);
      }

      bool clear(Offset at) => avoid == null || !Rect.fromLTRB(at.dx - w / 2, at.dy - w * 1.1, at.dx + w / 2, at.dy).overlaps(avoid);
      final fromRight = a.pose.at.dx >= f.dx;
      final free = [(fromRight, false), (!fromRight, false), (fromRight, true), (!fromRight, true)].where((s) => !taken.contains(s)).toList();
      final slot = free.firstWhere((s) => clear(spotAt(s)), orElse: () => free.first);
      taken.add(slot);
      final at = spotAt(slot);
      final go = ((a.pose.at - at).distance / _speed(a.creature.motion)).clamp(0.8, 3.0).toDouble();
      eaters.add(Eater(id: a.id, creature: a.creature, spot: at, facesLeft: at.dx > f.dx, delay: 0.15 + 0.3 * eaters.length, go: go));
    }
    return Meal(start: now, feeder: feeder, eaters: eaters, wasLeft: wasLeft);
  }
}
