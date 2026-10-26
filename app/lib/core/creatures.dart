import 'places.dart';

/// A place in the town you can go into, where the creatures a child colors
/// live (docs/town-map.md).
enum Habitat {
  zoo(PlaceKind.zoo),
  aquarium(PlaceKind.aquarium),
  dinoPark(PlaceKind.dinoPark),
  transport(PlaceKind.transport, vehicles: true);

  const Habitat(this.place, {this.vehicles = false});

  final PlaceKind place;

  /// Its residents are vehicles: counted 台, not 隻, and they drive in.
  final bool vehicles;

  List<Creature> get creatures => [for (final c in Creature.values) if (c.habitat == this) c];

  static Habitat? byName(String? name) => values.where((h) => h.name == name).firstOrNull;
  static Habitat? of(PlaceKind kind) => values.where((h) => h.place == kind).firstOrNull;
}

/// How a creature gets around its scene: [drive] along the road, [rail]
/// on the railway track.
enum Motion { walk, hop, swim, float, crawl, fly, drive, rail }

/// The coloring pages of the places you can go into, made in
/// docs/design/v3/src/animals.py and vehicles.py (same names), facing right.
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
  crab('螃蟹', Habitat.aquarium, Motion.crawl, 130),
  trex('暴龍', Habitat.dinoPark, Motion.walk, 200),
  triceratops('三角龍', Habitat.dinoPark, Motion.walk, 190),
  brachiosaurus('腕龍', Habitat.dinoPark, Motion.walk, 220),
  stegosaurus('劍龍', Habitat.dinoPark, Motion.walk, 190),
  pterosaur('翼龍', Habitat.dinoPark, Motion.fly, 170),
  babyDino('恐龍寶寶', Habitat.dinoPark, Motion.hop, 120),
  fireTruck('消防車', Habitat.transport, Motion.drive, 230),
  policeCar('警車', Habitat.transport, Motion.drive, 190),
  ambulance('救護車', Habitat.transport, Motion.drive, 200),
  bus('公車', Habitat.transport, Motion.drive, 240),
  scooter('機車', Habitat.transport, Motion.drive, 140),
  train('火車', Habitat.transport, Motion.rail, 230),
  airplane('飛機', Habitat.transport, Motion.fly, 200),
  helicopter('直升機', Habitat.transport, Motion.fly, 190);

  const Creature(this.label, this.habitat, this.motion, this.size);

  final String label;
  final Habitat habitat;
  final Motion motion;

  /// Width in scene units (a scene is 1000 across).
  final double size;

  static Creature? byName(String? name) => values.where((c) => c.name == name).firstOrNull;
}
