/// The kinds of places in a child's town (docs/town-map.md). Their names
/// match the town art (`assets/art/town/`, `town_layout_data.dart`).
enum PlaceKind {
  home('家'),
  grandma('阿公阿嬤家'),
  school('幼兒園'),
  park('公園'),
  food('好吃的店'),
  shop('商店'),
  zoo('動物園'),
  water('河邊海邊'),
  mountain('山上'),
  temple('廟'),
  station('車站'),
  travel('去旅行'),
  aquarium('海洋館');

  const PlaceKind(this.label);

  /// What the voice says and screen readers read.
  final String label;

  static PlaceKind byName(String name) => values.firstWhere((k) => k.name == name, orElse: () => home);
}

/// Animals children pick as their own character; stored by name.
const animals = ['bear', 'rabbit', 'cat', 'dog', 'panda', 'fox', 'frog', 'penguin'];

const animalNames = {
  'bear': '小熊',
  'rabbit': '小兔',
  'cat': '小貓',
  'dog': '小狗',
  'panda': '貓熊',
  'fox': '狐狸',
  'frog': '青蛙',
  'penguin': '企鵝',
};

/// Version 1 stored avatars as emoji.
const legacyAvatars = {
  '🐻': 'bear',
  '🐰': 'rabbit',
  '🐱': 'cat',
  '🐶': 'dog',
  '🐼': 'panda',
  '🦊': 'fox',
  '🐸': 'frog',
  '🐧': 'penguin',
};
