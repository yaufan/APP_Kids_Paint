import 'places.dart';

/// A place in the town you can go into, where the creatures a child colors
/// live (docs/town-map.md).
enum Habitat {
  zoo(PlaceKind.zoo),
  aquarium(PlaceKind.aquarium);

  const Habitat(this.place);

  final PlaceKind place;

  List<Creature> get creatures => [for (final c in Creature.values) if (c.habitat == this) c];

  static Habitat? byName(String? name) => values.where((h) => h.name == name).firstOrNull;
  static Habitat? of(PlaceKind kind) => values.where((h) => h.place == kind).firstOrNull;
}

/// How a creature gets around its scene.
enum Motion { walk, hop, swim, float, crawl }

/// The zoo's and the aquarium's coloring pages, drawn in
/// docs/design/v3/src/creatures.py (same names) facing right.
enum Creature {
  elephant('大象', Habitat.zoo, Motion.walk, 190),
  giraffe('長頸鹿', Habitat.zoo, Motion.walk, 190),
  lion('獅子', Habitat.zoo, Motion.walk, 170),
  panda('貓熊', Habitat.zoo, Motion.walk, 140),
  zebra('斑馬', Habitat.zoo, Motion.walk, 175),
  monkey('猴子', Habitat.zoo, Motion.hop, 130),
  clownfish('小丑魚', Habitat.aquarium, Motion.swim, 130),
  octopus('章魚', Habitat.aquarium, Motion.float, 140),
  turtle('海龜', Habitat.aquarium, Motion.swim, 170),
  whale('鯨魚', Habitat.aquarium, Motion.swim, 240),
  jellyfish('水母', Habitat.aquarium, Motion.float, 115),
  crab('螃蟹', Habitat.aquarium, Motion.crawl, 130);

  const Creature(this.label, this.habitat, this.motion, this.size);

  final String label;
  final Habitat habitat;
  final Motion motion;

  /// Width in scene units (a scene is 1000 across).
  final double size;

  static Creature? byName(String? name) => values.where((c) => c.name == name).firstOrNull;
}
