import 'places.dart';

/// A place in the town you can go into, where the creatures a child colors
/// live (docs/town-map.md).
enum Habitat {
  zoo(PlaceKind.zoo),
  aquarium(PlaceKind.aquarium),
  dinoPark(PlaceKind.dinoPark),
  transport(PlaceKind.transport, residents: Residents.vehicles),
  botanical(PlaceKind.botanical, residents: Residents.plants),
  insects(PlaceKind.insects),
  shop(PlaceKind.shop, residents: Residents.goods),
  space(PlaceKind.space, residents: Residents.space),
  // Postcards of eating out go to 好吃的店; inside it is the night market.
  nightMarket(PlaceKind.food, residents: Residents.visitors, ownName: '夜市'),
  polar(PlaceKind.polar, residents: Residents.visitors);

  const Habitat(this.place, {this.residents = Residents.animals, this.ownName});

  final PlaceKind place;

  /// A name of its own, when it is not its place's.
  final String? ownName;

  /// What it is called inside (and on its door): its place's name, or its own.
  String get label => ownName ?? place.label;

  /// Who lives there, which decides how we talk about them.
  final Residents residents;

  List<Creature> get creatures => [for (final c in Creature.values) if (c.habitat == this) c];

  static Habitat? byName(String? name) => values.where((h) => h.name == name).firstOrNull;
  static Habitat? of(PlaceKind kind) => values.where((h) => h.place == kind).firstOrNull;
}

/// Animals (and bugs) are counted 隻 and move in (住進); vehicles are
/// counted 台 and drive in (開進); plants are counted 棵 and are planted
/// (種到); the shop's goods are counted 個 and go on its shelves (上架到);
/// space's rockets and planets fly there (飛到); the night market's snacks
/// and the polar sea's mix of animals, snowmen and sleds simply come (來到).
enum Residents {
  animals('隻', '牠', '住進'),
  vehicles('台', '它', '開進'),
  plants('棵', '它', '種到'),
  goods('個', '它', '上架到'),
  space('個', '它', '飛到'),
  visitors('個', '它', '來到');

  const Residents(this.counter, this.pronoun, this.verb);

  final String counter;
  final String pronoun;
  final String verb;
}

/// How a creature gets around its scene: [drive] along the road, [rail]
/// on the railway track; plants stay where they grow and [sway]; the
/// shop's goods stand on a [shelf] until a customer buys them; in space
/// things [drift] about, turning slowly; penguins waddle and then [slide]
/// on their bellies.
enum Motion { walk, hop, swim, float, crawl, fly, drive, rail, sway, shelf, drift, slide }

/// The coloring pages of the places you can go into, made in
/// docs/design/v5 (same names), facing right.
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
  helicopter('直升機', Habitat.transport, Motion.fly, 190),
  sunflower('向日葵', Habitat.botanical, Motion.sway, 150),
  tulip('鬱金香', Habitat.botanical, Motion.sway, 110),
  cactus('仙人掌', Habitat.botanical, Motion.sway, 130),
  lotus('荷花', Habitat.botanical, Motion.sway, 140),
  strawberry('草莓', Habitat.botanical, Motion.sway, 130),
  rose('玫瑰', Habitat.botanical, Motion.sway, 110),
  butterfly('蝴蝶', Habitat.insects, Motion.fly, 130),
  ladybug('瓢蟲', Habitat.insects, Motion.crawl, 100),
  bee('蜜蜂', Habitat.insects, Motion.fly, 110),
  beetle('獨角仙', Habitat.insects, Motion.crawl, 140),
  dragonfly('蜻蜓', Habitat.insects, Motion.fly, 150),
  mantis('螳螂', Habitat.insects, Motion.walk, 150),
  // The shop's goods are about as tall as a shelf is high.
  milk('牛奶', Habitat.shop, Motion.shelf, 80),
  carrot('胡蘿蔔', Habitat.shop, Motion.shelf, 60),
  apple('蘋果', Habitat.shop, Motion.shelf, 100),
  banana('香蕉', Habitat.shop, Motion.shelf, 125),
  bread('麵包', Habitat.shop, Motion.shelf, 100),
  iceCream('冰淇淋', Habitat.shop, Motion.shelf, 70),
  bubbleTea('珍珠奶茶', Habitat.shop, Motion.shelf, 68),
  pudding('布丁', Habitat.shop, Motion.shelf, 125),
  rocket('火箭', Habitat.space, Motion.fly, 110),
  astronaut('太空人', Habitat.space, Motion.drift, 120),
  alien('外星人', Habitat.space, Motion.drift, 115),
  ufo('飛碟', Habitat.space, Motion.fly, 160),
  moon('月亮', Habitat.space, Motion.drift, 130),
  star('星星', Habitat.space, Motion.drift, 110),
  saturn('土星', Habitat.space, Motion.drift, 190),
  spaceCat('太空貓', Habitat.space, Motion.drift, 115),
  // The night market's snacks stand on the stalls; the goldfish swim in their pool.
  friedChicken('雞排', Habitat.nightMarket, Motion.shelf, 100),
  sausage('烤香腸', Habitat.nightMarket, Motion.shelf, 36),
  tanghulu('糖葫蘆', Habitat.nightMarket, Motion.shelf, 36),
  cottonCandy('棉花糖', Habitat.nightMarket, Motion.shelf, 85),
  sweetPotatoBalls('地瓜球', Habitat.nightMarket, Motion.shelf, 85),
  shavedIce('刨冰', Habitat.nightMarket, Motion.shelf, 115),
  takoyaki('章魚燒', Habitat.nightMarket, Motion.shelf, 125),
  goldfish('金魚', Habitat.nightMarket, Motion.swim, 110),
  penguin('企鵝', Habitat.polar, Motion.slide, 110),
  polarBear('北極熊', Habitat.polar, Motion.walk, 140),
  seal('海豹', Habitat.polar, Motion.crawl, 150),
  snowman('雪人', Habitat.polar, Motion.sway, 140),
  arcticFox('雪狐', Habitat.polar, Motion.hop, 120),
  orca('虎鯨', Habitat.polar, Motion.swim, 220),
  sled('雪橇', Habitat.polar, Motion.drive, 150),
  igloo('冰屋', Habitat.polar, Motion.sway, 190);

  const Creature(this.label, this.habitat, this.motion, this.size);

  final String label;
  final Habitat habitat;
  final Motion motion;

  /// Width in scene units (a scene is 1000 across).
  final double size;

  static Creature? byName(String? name) => values.where((c) => c.name == name).firstOrNull;
}
