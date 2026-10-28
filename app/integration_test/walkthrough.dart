import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/festivals.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/capture/capture_screen.dart';

/// Captures the screen under [name].
typedef Shot = Future<void> Function(String name);

/// Wraps the app so a screenshot can be taken from the widget tree.
final walkthroughKey = GlobalKey();

/// The app's clock during the walk-through: a weekday morning, later
/// Christmas Eve night and an autumn dusk.
var walkthroughNow = DateTime(2026, 10, 26, 10, 30);

/// The whole app as a child (and then a parent) uses it, with a screenshot
/// of every step. Shared by `test/flow_test.dart` (headless phone and tablet)
/// and `integration_test/app_flow_test.dart` (iPhone/iPad simulators). Only
/// the camera is skipped: [photo] is handed over as if it had just been taken.
/// [sounds] replaces the phone's (in `flutter test`, which has no audio).
Future<void> runWalkthrough(WidgetTester tester, {required Uint8List photo, required Shot shot, Sounds? sounds}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final storeDir = await tester.runAsync(() => Directory.systemTemp.createTemp('kids_paint_flow'));

  await tester.pumpWidget(RepaintBoundary(
    key: walkthroughKey,
    child: ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(ArtworkStore(storeDir!)),
        clockProvider.overrideWithValue(() => walkthroughNow),
        if (sounds != null) systemSoundsProvider.overrideWithValue(sounds),
      ],
      child: const KidsPaintApp(),
    ),
  ));

  // 0. The very first time: name the town and pick a friend.
  await waitFor(tester, find.text(Strings.welcome));
  await idle(tester, 800);
  await tester.enterText(find.byKey(const ValueKey('town-name')), '小宇');
  await tester.tap(find.byKey(const ValueKey('buddy-bear')));
  await idle(tester, 800);
  await shot('00_welcome');
  await tester.ensureVisible(find.bySemanticsLabel(Strings.letsGo));
  await idle(tester, 300);
  await tester.tap(find.bySemanticsLabel(Strings.letsGo));

  // 1. Day one: the town has only home; the big camera button invites a photo.
  await waitFor(tester, find.bySemanticsLabel(Strings.takePhoto));
  await idle(tester);
  await shot('01_town');

  // 2. Camera or album.
  await tester.tap(find.bySemanticsLabel(Strings.takePhoto));
  await waitFor(tester, find.bySemanticsLabel(Strings.camera));
  await idle(tester, 800);
  await shot('02_capture');

  // 3. The photo comes back from the camera -> magic, then both styles.
  GoRouter.of(tester.element(find.byType(CaptureScreen))).push('/styles', extra: photo);
  await waitFor(tester, find.text(Strings.magic));
  await idle(tester, 700);
  await shot('03_magic');
  await waitFor(tester, find.bySemanticsLabel(Strings.realistic));
  await idle(tester);
  await shot('04_styles');

  // 4. Pick the realistic page -> the postcard to color.
  await tester.tap(find.bySemanticsLabel(Strings.realistic));
  await waitFor(tester, find.bySemanticsLabel(Strings.bucket));
  await idle(tester);
  await shot('05_canvas_blank');

  // 5. Bucket-fill a few areas in different colors, then a crayon stroke.
  final canvas = tester.getRect(find.byKey(const ValueKey('page')));
  for (final (color, dx, dy) in [
    (kidPalette[0], 0.50, 0.30),
    (kidPalette[2], 0.50, 0.55),
    (kidPalette[5], 0.10, 0.10),
    (kidPalette[3], 0.85, 0.85),
  ]) {
    await tester.tap(find.byKey(ValueKey('swatch-$color')));
    await tester.pump();
    await tester.tapAt(canvas.topLeft + Offset(canvas.width * dx, canvas.height * dy));
    await idle(tester, 500);
  }
  await tester.tap(find.bySemanticsLabel(Strings.crayon));
  await tester.tap(find.byKey(ValueKey('swatch-${kidPalette[7]}')));
  await tester.pump();
  final start = canvas.topLeft + Offset(canvas.width * 0.3, canvas.height * 0.8);
  final gesture = await tester.startGesture(start);
  for (var i = 1; i <= 12; i++) {
    await gesture.moveTo(start + Offset(i * canvas.width * 0.03, (i.isEven ? -1 : 1) * 12));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await idle(tester, 300);
  // Some of the magic pen's other kinds.
  for (final (pen, y) in [(Strings.penDots, 0.2), (Strings.penNeon, 0.45), (Strings.penStripes, 0.7)]) {
    await tester.tap(find.bySemanticsLabel(pen));
    await tester.pump();
    final from = canvas.topLeft + Offset(canvas.width * 0.15, canvas.height * y);
    final g = await tester.startGesture(from);
    for (var i = 1; i <= 12; i++) {
      await g.moveTo(from + Offset(i * canvas.width * 0.05, (i.isEven ? -1 : 1) * 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await idle(tester, 300);
  }
  await shot('05b_pens');
  // More colors: the pastel set, then back to the bright one.
  await tester.tap(find.byKey(const ValueKey('palette-1')));
  await idle(tester, 300);
  await shot('05c_colors');
  await tester.tap(find.byKey(const ValueKey('palette-0')));
  await idle(tester, 200);
  // The rainbow pen and glitter, then a few stamps.
  for (final (tool, y) in [(Strings.rainbow, 0.62), (Strings.glitter, 0.92)]) {
    await tester.tap(find.bySemanticsLabel(tool));
    await tester.pump();
    final from = canvas.topLeft + Offset(canvas.width * 0.12, canvas.height * y);
    final g = await tester.startGesture(from);
    for (var i = 1; i <= 14; i++) {
      await g.moveTo(from + Offset(i * canvas.width * 0.05, (i.isEven ? -1 : 1) * 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await idle(tester, 300);
  }
  await tester.tap(find.bySemanticsLabel(Strings.stamp));
  await idle(tester, 400);
  final stamped = tester.getRect(find.byKey(const ValueKey('page')));
  for (final (shape, color, dx, dy) in [('星星', kidPalette[2], 0.15, 0.12), ('愛心', kidPalette[7], 0.85, 0.15), ('花朵', kidPalette[6], 0.12, 0.42)]) {
    await tester.tap(find.bySemanticsLabel(Strings.stampOf(shape)));
    await tester.tap(find.byKey(ValueKey('swatch-$color')));
    await tester.pump();
    await tester.tapAt(stamped.topLeft + Offset(stamped.width * dx, stamped.height * dy));
    await idle(tester, 300);
  }
  await idle(tester);
  await shot('06_canvas_colored');

  // 6. Done -> where to? -> the park.
  await tester.tap(find.bySemanticsLabel(Strings.done));
  final park = find.bySemanticsLabel(Strings.sendTo(PlaceKind.park.label));
  await waitFor(tester, park);
  await idle(tester);
  await shot('07_where_to');
  await tester.tap(park);
  await waitFor(tester, find.text(Strings.newPlace(PlaceKind.park.label)));
  await idle(tester, 900);
  await shot('08_sent');

  // 7. Back in town by itself: the park was just built, with the postcard on it.
  await waitFor(tester, find.bySemanticsLabel(Strings.pinLabel(PlaceKind.park.label, 1)));
  await idle(tester, 2000);
  await shot('09_town_new_place');

  final saved = await tester.runAsync(() => db.select(db.artworks).get());
  expect(saved, hasLength(1));
  expect(saved!.single.isCompleted, isTrue);
  expect(saved.single.sentAt, isNotNull);
  expect(File('${storeDir.path}/${saved.single.folder}/colored.png').existsSync(), isTrue);

  // 8. The album.
  await tester.tap(find.bySemanticsLabel(Strings.album));
  await waitFor(tester, find.bySemanticsLabel(RegExp('的明信片\$')));
  await idle(tester);
  await shot('10_album');

  // 9. Parent gate, parent mode, privacy.
  await tester.tap(find.bySemanticsLabel(Strings.backToMap));
  await waitFor(tester, find.byTooltip(Strings.parentMode));
  await idle(tester, 500);
  await tester.tap(find.byTooltip(Strings.parentMode));
  await waitFor(tester, find.text(Strings.parentGateTitle));
  await idle(tester, 600);
  await shot('11_parent_gate');
  for (final digit in '${answerParentGate(tester)}'.split('')) {
    await tester.tap(find.byKey(ValueKey('gate-key-$digit')));
    await tester.pump();
  }
  await waitFor(tester, find.text(Strings.dailyLimit));
  await idle(tester, 500);
  await shot('12_parent_mode');
  // Further down the list (built only when scrolled to).
  await tester.scrollUntilVisible(find.text(Strings.privacy), 300,
      scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first);
  await tester.pump();
  await tester.tap(find.text(Strings.privacy));
  await waitFor(tester, find.text(Strings.allOnPhone));
  await idle(tester, 500);
  await shot('13_privacy');

  // 10. Christmas Eve night: the town is lit, Gugu says good night and brings
  //     a letter with the Christmas page.
  walkthroughNow = DateTime(2026, 12, 24, 19, 30);
  GoRouter.of(tester.element(find.text(Strings.allOnPhone))).go('/');
  final letter = find.bySemanticsLabel(Strings.openLetter(Festival.christmas.label));
  await waitFor(tester, letter);
  await idle(tester, 1200);
  await shot('14_town_night');
  await tester.tap(letter);
  await waitFor(tester, find.byKey(const ValueKey('page')));
  await idle(tester, 600);
  final page = tester.getRect(find.byKey(const ValueKey('page')));
  for (final (color, dx, dy) in [(kidPalette[3], 0.5, 0.45), (kidPalette[2], 0.5, 0.1), (kidPalette[0], 0.25, 0.9)]) {
    await tester.tap(find.byKey(ValueKey('swatch-$color')));
    await tester.pump();
    await tester.tapAt(page.topLeft + Offset(page.width * dx, page.height * dy));
    await idle(tester, 500);
  }
  await idle(tester);
  await shot('15_festival_page');

  // 11. Blank paper at dusk: scribble with the crayon, then color the paper.
  walkthroughNow = DateTime(2026, 10, 26, 17, 30);
  await tester.tap(find.bySemanticsLabel(Strings.backToMap));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await tester.tap(find.bySemanticsLabel(Strings.blankPaper));
  await waitFor(tester, find.bySemanticsLabel(Strings.paperColor));
  await waitFor(tester, find.byKey(const ValueKey('page')));
  await idle(tester, 600);
  final paper = tester.getRect(find.byKey(const ValueKey('page')));
  for (final (color, y) in [(kidPalette[5], 0.3), (kidPalette[0], 0.5), (kidPalette[3], 0.7)]) {
    await tester.tap(find.byKey(ValueKey('swatch-$color')));
    await tester.pump();
    final from = paper.topLeft + Offset(paper.width * 0.15, paper.height * y);
    final stroke = await tester.startGesture(from);
    for (var i = 1; i <= 14; i++) {
      await stroke.moveTo(from + Offset(i * paper.width * 0.05, (i.isEven ? -1 : 1) * paper.height * 0.04));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await stroke.up();
    await tester.pump();
  }
  await tester.tap(find.bySemanticsLabel(Strings.paperColor));
  await tester.tap(find.byKey(ValueKey('swatch-${kidPalette[2]}')));
  await tester.pump();
  await tester.tapAt(paper.center);
  await idle(tester);
  await shot('16_blank_paper');

  // 12. Send it home; back in town at dusk.
  await tester.tap(find.bySemanticsLabel(Strings.done));
  final home = find.bySemanticsLabel(Strings.sendTo(PlaceKind.home.label));
  await waitFor(tester, home);
  await idle(tester, 600);
  await tester.tap(home);
  await waitFor(tester, find.bySemanticsLabel(Strings.pinLabel(PlaceKind.home.label, 1)));
  await idle(tester, 2000);
  await shot('17_town_dusk');

  // 13. The zoo: color an elephant and a monkey, and they move in.
  walkthroughNow = DateTime(2026, 10, 27, 10);
  await tester.tap(find.bySemanticsLabel(Strings.places));
  await waitFor(tester, find.bySemanticsLabel(Strings.goTo(Habitat.zoo.label)));
  await idle(tester, 600);
  await shot('17b_places');
  await tester.tap(find.bySemanticsLabel(Strings.goTo(Habitat.zoo.label)));
  await waitFor(tester, find.bySemanticsLabel(Strings.drawNew(Habitat.zoo.label)));
  await idle(tester, 800);
  await shot('18_zoo_empty');
  for (final (i, creature) in [Creature.elephant, Creature.monkey].indexed) {
    await colorCreature(tester, creature, [kidPalette[i == 0 ? 5 : 8], kidPalette[i == 0 ? 7 : 9], kidPalette[2]],
        onPicker: i == 0 ? () => shot('18b_pick_creature') : null);
    if (i == 0) await shot('19_creature_page');
    await tester.tap(find.bySemanticsLabel(Strings.done));
    await waitFor(tester, find.bySemanticsLabel(Strings.resident(creature.label)));
    await idle(tester, 1800);
  }
  await shot('20_zoo');

  // 14. The aquarium: a whale and a jellyfish.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.aquarium);
  for (final (i, creature) in [Creature.whale, Creature.jellyfish].indexed) {
    await colorCreature(tester, creature, [kidPalette[i == 0 ? 5 : 7], kidPalette[2], kidPalette[0]]);
    await tester.tap(find.bySemanticsLabel(Strings.done));
    await waitFor(tester, find.bySemanticsLabel(Strings.resident(creature.label)));
    await idle(tester, 1800);
  }
  await shot('21_aquarium');

  // 15. The dinosaur park: a T. rex and a pterosaur that flies.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.dinoPark);
  for (final (i, creature) in [Creature.trex, Creature.pterosaur].indexed) {
    await colorCreature(tester, creature, [kidPalette[i == 0 ? 3 : 1], kidPalette[i == 0 ? 2 : 7], kidPalette[4]]);
    await tester.tap(find.bySemanticsLabel(Strings.done));
    await waitFor(tester, find.bySemanticsLabel(Strings.resident(creature.label)));
    await idle(tester, 1800);
  }
  // Tap the T. rex: it jumps and says something.
  await tester.tap(find.bySemanticsLabel(Strings.resident(Creature.trex.label)), warnIfMissed: false);
  await idle(tester, 700);
  await shot('22_dino_park');

  // 16. The transport museum: a fire truck on the road, a train on the
  // track, a plane in the sky.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.transport);
  for (final (i, creature) in [Creature.fireTruck, Creature.train, Creature.airplane].indexed) {
    await colorCreature(tester, creature, [kidPalette[[0, 5, 6][i]], kidPalette[2], kidPalette[7]]);
    await tester.tap(find.bySemanticsLabel(Strings.done));
    await waitFor(tester, find.bySemanticsLabel(Strings.resident(creature.label)));
    await idle(tester, 1800);
  }
  await shot('24_transport');

  // 17. The botanical garden: a sunflower and a tulip, swaying where they grow.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.botanical);
  for (final (i, creature) in [Creature.sunflower, Creature.tulip].indexed) {
    await colorCreature(tester, creature, i == 0 ? [kidPalette[2], kidPalette[3], kidPalette[8]] : [kidPalette[0], kidPalette[3], kidPalette[7]]);
    await tester.tap(find.bySemanticsLabel(Strings.done));
    await waitFor(tester, find.bySemanticsLabel(Strings.resident(creature.label)));
    await idle(tester, 1800);
  }
  await shot('25_botanical');

  // 18. The insect museum: a butterfly that flies, a ladybug that crawls.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.insects);
  for (final (i, creature) in [Creature.butterfly, Creature.ladybug].indexed) {
    await colorCreature(tester, creature, i == 0 ? [kidPalette[1], kidPalette[6], kidPalette[11]] : [kidPalette[0], kidPalette[11], kidPalette[3]]);
    await tester.tap(find.bySemanticsLabel(Strings.done));
    await waitFor(tester, find.bySemanticsLabel(Strings.resident(creature.label)));
    await idle(tester, 1800);
  }
  await shot('26_insects');

  // 19. The shop: milk and a carrot go on the shelves, and one of the
  //     child's animals comes in to buy something and pays a coin.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.shop);
  for (final (i, creature) in [Creature.milk, Creature.carrot].indexed) {
    await colorCreature(tester, creature, i == 0 ? [kidPalette[10], kidPalette[5], kidPalette[2]] : [kidPalette[1], kidPalette[2], kidPalette[3]]);
    await tester.tap(find.bySemanticsLabel(Strings.done));
    await waitFor(tester, find.bySemanticsLabel(Strings.resident(creature.label)));
    await idle(tester, 1800);
  }
  await waitFor(tester, find.bySemanticsLabel(Strings.customer));
  await idle(tester, 2600);
  await shot('27_shop');

  // 20. Space: a rocket that takes off when tapped.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.space);
  await colorCreature(tester, Creature.rocket, [kidPalette[0], kidPalette[5], kidPalette[2]]);
  await tester.tap(find.bySemanticsLabel(Strings.done));
  await waitFor(tester, find.bySemanticsLabel(Strings.resident(Creature.rocket.label)));
  await idle(tester, 2000);
  await tester.tap(find.bySemanticsLabel(Strings.resident(Creature.rocket.label)), warnIfMissed: false);
  await idle(tester, 1800);
  await shot('28_space');

  // 21. The night market: a ring thrown over a snack.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.food);
  await colorCreature(tester, Creature.friedChicken, [kidPalette[8], kidPalette[0], kidPalette[2]]);
  await tester.tap(find.bySemanticsLabel(Strings.done));
  await waitFor(tester, find.bySemanticsLabel(Strings.resident(Creature.friedChicken.label)));
  await idle(tester, 2000);
  await tester.tap(find.bySemanticsLabel(Strings.resident(Creature.friedChicken.label)), warnIfMissed: false);
  await idle(tester, 1100);
  await shot('29_night_market');

  // 22. The polar sea: a penguin in the snow.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.polar);
  await colorCreature(tester, Creature.penguin, [kidPalette[5], kidPalette[1], kidPalette[3]]);
  await tester.tap(find.bySemanticsLabel(Strings.done));
  await waitFor(tester, find.bySemanticsLabel(Strings.resident(Creature.penguin.label)));
  await idle(tester, 2500);
  await shot('30_polar');

  // 23. The candy house: a gummy bear and a donut that rolls.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.blankPaper));
  await idle(tester, 800);
  await enterScene(tester, PlaceKind.candy);
  for (final (i, creature) in [Creature.gummyBear, Creature.donut].indexed) {
    await colorCreature(tester, creature, [kidPalette[i == 0 ? 0 : 7], kidPalette[2], kidPalette[4]],
        onPicker: i == 0 ? () => shot('31a_candy_pick') : null);
    await tester.tap(find.bySemanticsLabel(Strings.done));
    await waitFor(tester, find.bySemanticsLabel(Strings.resident(creature.label)));
    await idle(tester, 1800);
  }
  await shot('31_candy');

  // 19. The album as one timeline.
  await tester.tap(find.bySemanticsLabel(Strings.backToTown));
  await waitFor(tester, find.bySemanticsLabel(Strings.album));
  await idle(tester, 600);
  await tester.tap(find.bySemanticsLabel(Strings.album));
  await waitFor(tester, find.bySemanticsLabel(Strings.byTime));
  await idle(tester, 500);
  await tester.tap(find.bySemanticsLabel(Strings.byTime));
  await waitFor(tester, find.byKey(const ValueKey('timeline')));
  await idle(tester);
  await shot('23_album_timeline');

  // Unmount so drift's stream queries shut down before the test ends.
  await tester.pumpWidget(const SizedBox());
  await idle(tester, 200);
  await tester.runAsync(() async {
    await db.close();
    await storeDir.delete(recursive: true);
  });
}

/// From the town into a place you can go into, with the places button.
Future<void> enterScene(WidgetTester tester, PlaceKind place) async {
  final habitat = Habitat.of(place)!;
  await tester.tap(find.bySemanticsLabel(Strings.places));
  await waitFor(tester, find.bySemanticsLabel(Strings.goTo(habitat.label)));
  await idle(tester, 500);
  await tester.tap(find.bySemanticsLabel(Strings.goTo(habitat.label)));
  await waitFor(tester, find.bySemanticsLabel(Strings.drawNew(habitat.label, residents: habitat.residents)));
}

/// Picks [creature] in its scene and bucket-fills a few areas with [colors].
/// [onPicker] runs while the cards to pick from are showing.
Future<void> colorCreature(WidgetTester tester, Creature creature, List<int> colors, {Future<void> Function()? onPicker}) async {
  await tester.tap(find.bySemanticsLabel(Strings.drawNew(creature.habitat.label, residents: creature.habitat.residents)));
  await waitFor(tester, find.byKey(ValueKey('creature-${creature.name}')));
  await idle(tester, 500);
  await onPicker?.call();
  await tester.tap(find.byKey(ValueKey('creature-${creature.name}')));
  await waitFor(tester, find.byKey(const ValueKey('page')));
  await idle(tester, 600);
  final page = tester.getRect(find.byKey(const ValueKey('page')));
  final spots = [(0.5, 0.56), (0.75, 0.42), (0.3, 0.7)];
  for (var i = 0; i < colors.length; i++) {
    await tester.tap(find.byKey(ValueKey('swatch-${colors[i]}')));
    await tester.pump();
    await tester.tapAt(page.topLeft + Offset(page.width * spots[i].$1, page.height * spots[i].$2));
    await idle(tester, 400);
  }
  await idle(tester, 600);
}

/// Lets real async work (isolates, files, image decoding) run until [until] shows up.
Future<void> waitFor(WidgetTester tester, Finder until, {int seconds = 60}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    if (until.evaluate().isNotEmpty) return;
  }
  fail('timed out waiting for $until');
}

/// Lets animations and background work settle for about [ms] milliseconds.
Future<void> idle(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Reads the parent gate question (「七」加「八」) and returns the sum.
int answerParentGate(WidgetTester tester) {
  const digits = '零一二三四五六七八九';
  final question = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.startsWith('「'));
  final numbers = RegExp('「(.)」').allMatches(question).map((m) => digits.indexOf(m.group(1)!));
  return numbers.reduce((a, b) => a + b);
}

/// A drawn "photo" of a cup on a saucer, for devices where test files are
/// not available.
Uint8List syntheticPhoto() {
  final image = img.Image(width: 900, height: 700)..clear(img.ColorRgb8(196, 226, 240));
  img.fillRect(image, x1: 0, y1: 470, x2: 900, y2: 700, color: img.ColorRgb8(170, 120, 80));
  img.fillCircle(image, x: 760, y: 120, radius: 70, color: img.ColorRgb8(255, 210, 60));
  img.fillCircle(image, x: 450, y: 520, radius: 230, color: img.ColorRgb8(240, 240, 235));
  img.fillRect(image, x1: 300, y1: 260, x2: 600, y2: 520, color: img.ColorRgb8(215, 60, 50), radius: 60);
  img.fillCircle(image, x: 450, y: 270, radius: 150, color: img.ColorRgb8(235, 235, 230));
  img.fillCircle(image, x: 450, y: 275, radius: 120, color: img.ColorRgb8(120, 70, 40));
  img.fillCircle(image, x: 640, y: 390, radius: 60, color: img.ColorRgb8(215, 60, 50));
  img.fillCircle(image, x: 640, y: 390, radius: 30, color: img.ColorRgb8(240, 240, 235));
  return img.encodeJpg(image, quality: 90);
}
