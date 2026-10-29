import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/creature_lines.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/scene/feeding.dart';
import 'package:kids_paint/features/scene/motion.dart';

import 'postcard_back_test.dart' show RecordingVoice;
import 'town_toys_test.dart' show RecordingSounds;

/// Animals make their sounds and come to eat (0.19).
void main() {
  group('sounds', () {
    test('every animal where there is food, and every vehicle, makes a sound of its own', () {
      for (final c in Creature.values) {
        if (eats(c) || c.habitat == Habitat.transport) expect(isCall(callOf(c)), isTrue, reason: c.name);
      }
      expect(callOf(Creature.cow), Sfx.moo);
      expect(callOf(Creature.garbageTruck), Sfx.elise, reason: 'Für Elise, like the garbage trucks in Taiwan');
      expect(callOf(Creature.sunflower), boingOf(Creature.sunflower), reason: 'plants still boing');
    });

    test('every sound has its file', () {
      for (final sfx in Sfx.values) {
        expect(File('assets/sounds/${sfx.file}.wav').existsSync(), isTrue, reason: sfx.file);
      }
    });
  });

  group('who comes to eat', () {
    final phone = SceneView(const Size(390, 844)), tablet = SceneView(const Size(1024, 768));
    final farm = feeders[Habitat.farm]!;

    ({int id, Creature creature, Pose pose, Rect area}) at(int id, Creature c, double x, SceneView view) {
      final area = roamArea(c, view);
      return (id: id, creature: c, pose: (at: Offset(x, 900), left: false, tilt: 0, squash: 1), area: area);
    }

    test('animals that get about come; plants, vehicles and the snowman do not', () {
      expect([Creature.cow, Creature.chick, Creature.orca, Creature.penguin, Creature.bee, Creature.snail].every(eats), isTrue);
      expect([Creature.tractor, Creature.snowman, Creature.sled, Creature.dinoEgg, Creature.sunflower, Creature.bus, Creature.donut].any(eats), isFalse);
      expect(feeders.keys, containsAll([Habitat.zoo, Habitat.aquarium, Habitat.dinoPark, Habitat.insects, Habitat.polar, Habitat.farm]));
    });

    test('the nearest three come on a phone, four on a tablet; each faces the food from its own side', () {
      final around = [
        at(1, Creature.cow, 330, phone),
        at(2, Creature.pig, 700, phone),
        at(3, Creature.tractor, 480, phone), // the nearest, but it does not eat
        at(4, Creature.hen, 520, phone),
        at(5, Creature.sheep, 300, phone),
        at(6, Creature.goat, 720, phone),
      ];
      final meal = Meal.plan(now: 10, feeder: farm, around: around, view: phone);
      expect(meal.eaters.map((e) => e.id), [4, 1, 5]);
      final hen = meal.eater(4)!, cow = meal.eater(1)!, sheep = meal.eater(5)!;
      expect(hen.spot.dx, greaterThan(farm.at.dx), reason: 'it came from the right');
      expect(hen.facesLeft, isTrue);
      expect(cow.spot.dx, lessThan(farm.at.dx));
      expect(cow.facesLeft, isFalse);
      expect(sheep.spot.dy, lessThan(cow.spot.dy), reason: 'the left side was taken: it eats a little behind');
      expect({for (final e in meal.eaters) e.spot}.length, 3);
      for (final e in meal.eaters) {
        expect(phone.visible.contains(e.spot), isTrue, reason: 'on screen');
      }
      expect(Meal.plan(now: 10, feeder: farm, around: [for (final a in around) at(a.id, a.creature, a.pose.at.dx, tablet)], view: tablet).eaters,
          hasLength(4));
    });

    test('nobody eats under the draw button while there is room elsewhere', () {
      final button = Rect.fromPoints(phone.toScene(const Offset(390 - 134, 844 - 134)), phone.toScene(const Offset(390, 844)));
      final cow = at(1, Creature.cow, 700, phone);
      final w = Creature.cow.size * phone.creatureScale;
      final spot = Meal.plan(now: 0, feeder: farm, around: [cow], view: phone, avoid: button).eaters.single.spot;
      expect(Rect.fromLTRB(spot.dx - w / 2, spot.dy - w * 1.1, spot.dx + w / 2, spot.dy).overlaps(button), isFalse);
      expect(Meal.plan(now: 0, feeder: farm, around: [cow], view: phone).eaters.single.spot.dx, greaterThan(farm.at.dx),
          reason: 'with nothing in the way it eats on the side it came from');
    });

    test('an orca at the polar sea eats at the edge of its water', () {
      final orca = at(1, Creature.orca, 600, phone);
      final meal = Meal.plan(now: 0, feeder: feeders[Habitat.polar]!, around: [orca], view: phone);
      expect(meal.eaters.single.spot.dy, orca.area.bottom);
    });

    test('it goes to the food, eats there, and goes back to its own way', () {
      final cow = at(1, Creature.cow, 330, phone);
      final meal = Meal.plan(now: 0, feeder: farm, around: [cow], view: phone);
      final e = meal.eater(1)!;
      const elsewhere = (at: Offset(250, 800), left: true, tilt: 0.02, squash: 1.0);
      expect(e.pose(0, natural: elsewhere, from: cow.pose), elsewhere, reason: 'not yet');
      final half = e.pose(e.delay + e.go / 2, natural: elsewhere, from: cow.pose);
      expect(half.at.dx, inExclusiveRange(cow.pose.at.dx, e.spot.dx));
      final eating = e.pose(e.arrive + 1, natural: elsewhere, from: cow.pose);
      expect((eating.at - e.spot).distance, lessThan(1));
      expect(eating.left, e.facesLeft);
      expect(e.pose(e.home, natural: elsewhere, from: cow.pose), elsewhere, reason: 'back');
      expect(meal.length, e.home);
    });

    test('the food pops up full, goes down while they eat, and stays full when nobody comes', () {
      final meal = Meal.plan(now: 0, feeder: farm, around: [at(1, Creature.cow, 330, phone)], view: phone, wasLeft: Meal.leftover);
      final e = meal.eaters.single;
      expect(meal.level(0), Meal.leftover);
      expect(meal.level(e.arrive), 1);
      expect(meal.level((e.arrive + e.full) / 2), inExclusiveRange(Meal.leftover, 1));
      expect(meal.level(e.full), closeTo(Meal.leftover, 1e-9));
      final nobody = Meal.plan(now: 0, feeder: farm, around: [at(1, Creature.tractor, 330, phone)], view: phone);
      expect(nobody.eaters, isEmpty);
      expect(nobody.level(5), 1);
      expect(nobody.length, Meal.fill);
    });
  });

  group('at the farm', () {
    late AppDatabase db;
    late ArtworkService service;
    late RecordingSounds sounds;
    late RecordingVoice voice;
    final ids = <Creature, int>{};

    Rect where(WidgetTester tester, Creature c) => tester.getRect(find.bySemanticsLabel(Strings.resident(c.label)));

    Future<void> pumpFarm(WidgetTester tester, List<Creature> residents) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = ArtworkStore(Directory.systemTemp.createTempSync('kp_feed'));
      service = ArtworkService(ArtworkRepository(db), store);
      sounds = RecordingSounds();
      voice = RecordingVoice();
      await tester.runAsync(() async {
        await SettingsRepository(db).setWelcomed();
        final childId = (await ChildRepository(db).ensureDefault()).id;
        final place = await PlaceRepository(db).defaultPlace(childId, Habitat.farm.place);
        for (final c in residents) {
          final art = await service.saveTemplate(childId: childId, template: c.name, png: File('assets/pages/${c.name}.png').readAsBytesSync());
          final page = await service.load(art.id);
          page.document.fill(300, 470, 0xFFFF9AAE);
          await service.send(page, place);
          ids[c] = art.id;
        }
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          artworkStoreProvider.overrideWithValue(store),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 3, 10)),
          systemSoundsProvider.overrideWithValue(sounds),
          systemVoiceProvider.overrideWithValue(voice),
        ],
        child: const KidsPaintApp(),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/scene/farm');
      for (var i = 0; i < 40 && find.bySemanticsLabel(Strings.resident(residents.first.label)).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Their pictures load from files: wait until they are on screen.
      for (var i = 0; i < 40 && residents.any((c) => where(tester, c).height == 0); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (final c in residents) {
        expect(where(tester, c).height, greaterThan(0), reason: c.name);
      }
    }

    Future<void> wait(WidgetTester tester, Duration time) async {
      for (var left = time; left > Duration.zero; left -= const Duration(milliseconds: 100)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // The app's streams close with timers of their own: let them run before the end.
    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('tap the food: the nearest animals come and eat, then one says it was yummy', (tester) async {
      await pumpFarm(tester, [Creature.cow, Creature.pig, Creature.hen, Creature.chick, Creature.tractor]);
      final food = find.bySemanticsLabel(Strings.feed(feeders[Habitat.farm]!.food));
      expect(food, findsOneWidget);
      final bowl = tester.getRect(food);
      sounds.played.clear();
      voice.said.clear();

      await tester.tap(food);
      await tester.pump();
      expect(sounds.played, [Sfx.serve]);

      // Everyone who comes is there by now (the slowest takes three seconds), eating.
      await wait(tester, const Duration(milliseconds: 4300));
      final near = [
        for (final c in [Creature.cow, Creature.pig, Creature.hen, Creature.chick])
          if ((where(tester, c).bottomCenter - bowl.bottomCenter).distance < bowl.width * 1.6) c,
      ];
      expect(near, hasLength(3), reason: 'three come on a phone');
      expect((where(tester, Creature.tractor).bottomCenter - bowl.bottomCenter).distance, greaterThan(bowl.width * 0.4),
          reason: 'the tractor does not eat');
      expect(sounds.played.where((s) => s == Sfx.munch).length, greaterThanOrEqualTo(3));

      // The first to finish calls and says it was yummy.
      await wait(tester, const Duration(milliseconds: 2500));
      expect(sounds.played.where((s) => {Sfx.moo, Sfx.oink, Sfx.cluck, Sfx.peep}.contains(s)), isNotEmpty);
      expect(voice.said.where(fedLines.contains), hasLength(1));

      // Once they are all back, more food can go out.
      await wait(tester, const Duration(seconds: 5));
      sounds.played.clear();
      await tester.tap(food);
      await tester.pump();
      expect(sounds.played, [Sfx.serve]);
      await wait(tester, const Duration(seconds: 10));
      await unmount(tester);
    });

    testWidgets('a tapped animal makes its sound and then talks', (tester) async {
      await pumpFarm(tester, [Creature.cow, Creature.tractor]);
      sounds.played.clear();
      voice.said.clear();
      await tester.tap(find.bySemanticsLabel(Strings.resident(Creature.cow.label)));
      await tester.pump();
      expect(sounds.played, [Sfx.moo]);
      expect(voice.said, isEmpty, reason: 'the moo first');
      await wait(tester, const Duration(milliseconds: 800));
      expect(voice.said, hasLength(1));
      // Somewhere on the tractor nothing stands in front of (the cow, the food), once there is.
      Offset? clear() {
        final tractor = where(tester, Creature.tractor);
        final over = [where(tester, Creature.cow), tester.getRect(find.bySemanticsLabel(Strings.feed('牧草')))];
        for (var y = 0.1; y < 1; y += 0.2) {
          for (var x = 0.1; x < 1; x += 0.2) {
            final at = Offset(tractor.left + tractor.width * x, tractor.top + tractor.height * y);
            if (!over.any((r) => r.contains(at))) return at;
          }
        }
        return null;
      }
      var spot = clear();
      for (var i = 0; i < 40 && spot == null; i++) {
        await tester.pump(const Duration(milliseconds: 250));
        spot = clear();
      }
      await tester.tapAt(spot!);
      await tester.pump();
      expect(sounds.played.last, Sfx.putt);
      await wait(tester, const Duration(seconds: 4));
      await unmount(tester);
    });
  });
}
