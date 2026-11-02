import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/core/voice.dart';
import 'package:kids_paint/features/scene/motion.dart';

import 'islands_test.dart' show RecordingSounds;

/// 2.1: a child presses a resident, lifts it up and puts it somewhere else.
void main() {
  group('put down somewhere new', () {
    final phone = SceneView(const Size(390, 844));

    test('it glides from where it was let go and then keeps near the spot', () {
      final area = roamArea(Creature.cow, phone);
      final to = Offset(area.left + 40, area.top + 20);
      const from = Offset(120, 300); // up in the sky, where the finger let go
      final start = settledAt(Motion.walk, 50, 7, area, from: from, to: to, since: 50);
      expect((start.at - from).distance, lessThan(1e-6), reason: 'no jump when let go');
      final near = nearArea(Motion.walk, area, to);
      expect(area.contains(near.topLeft) && area.contains(near.bottomRight), isTrue);
      expect(near.contains(to), isTrue);
      for (var t = 55.0; t < 400; t += 7.3) {
        final p = settledAt(Motion.walk, t, 7, area, from: from, to: to, since: 50).at;
        expect(near.inflate(1).contains(p), isTrue, reason: 'at $t it wanders near the spot');
      }
    });

    test('a plant stays right where it is put', () {
      final area = roamArea(Creature.sunflower, phone);
      final to = Offset(area.center.dx, area.bottom);
      final p = settledAt(Motion.sway, 99, 3, area, from: to, to: to, since: 10).at;
      expect((p - to).distance, lessThan(1e-6));
    });
  });

  group('at the zoo', () {
    late AppDatabase db;

    Rect where(WidgetTester tester, Creature c) => tester.getRect(find.bySemanticsLabel(Strings.resident(c.label)));

    Future<RecordingSounds> pumpZoo(WidgetTester tester, List<Creature> residents) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = ArtworkStore(Directory.systemTemp.createTempSync('kp_move'));
      final service = ArtworkService(ArtworkRepository(db), store);
      final sounds = RecordingSounds();
      await tester.runAsync(() async {
        await SettingsRepository(db).setWelcomed();
        final childId = (await ChildRepository(db).ensureDefault()).id;
        final place = await PlaceRepository(db).defaultPlace(childId, Habitat.zoo.place);
        for (final c in residents) {
          final art = await service.saveTemplate(childId: childId, template: c.name, png: File('assets/pages/${c.name}.png').readAsBytesSync());
          final page = await service.load(art.id);
          page.document.fill(300, 470, 0xFFFF9AAE);
          await service.send(page, place);
        }
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          artworkStoreProvider.overrideWithValue(store),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 3, 10)),
          systemSoundsProvider.overrideWithValue(sounds),
          systemVoiceProvider.overrideWithValue(const SilentVoice()),
        ],
        child: const KidsPaintApp(),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/scene/zoo');
      for (var i = 0; i < 40 && find.bySemanticsLabel(Strings.resident(residents.first.label)).evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      for (var i = 0; i < 40 && residents.any((c) => where(tester, c).height == 0); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(where(tester, residents.first).height, greaterThan(0));
      return sounds;
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    }

    for (final (how, press) in [('pressed a moment, then carried', true), ('dragged straight away', false)]) {
      testWidgets('a resident $how goes where it is put and stays round there', (tester) async {
        final sounds = await pumpZoo(tester, [Creature.elephant]);
        final before = where(tester, Creature.elephant);
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        // Somewhere else on the grass: the other side of the screen, a little lower.
        final target = Offset(before.center.dx < screen.width / 2 ? screen.width * 0.75 : screen.width * 0.25, before.center.dy + 40);
        sounds.played.clear();

        final finger = await tester.startGesture(before.center);
        if (press) {
          await tester.pump(const Duration(milliseconds: 350));
          expect(sounds.played, contains(Sfx.boingHigh), reason: 'picked up');
        }
        const steps = 12;
        final step = (target - before.center) / steps.toDouble();
        for (var i = 0; i < steps; i++) {
          await finger.moveBy(step);
          await tester.pump(const Duration(milliseconds: 16));
        }
        final carried = where(tester, Creature.elephant);
        expect((carried.center - target).distance, lessThan(carried.height * 0.6), reason: 'it follows the finger');
        await finger.up();
        await tester.pump();
        expect(sounds.played, containsAll([Sfx.boingHigh, Sfx.boingLow]));

        // A few seconds later it is still over there, not back where it was.
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        final after = where(tester, Creature.elephant);
        expect((after.center.dx - target.dx).abs(), lessThan(140), reason: 'it wanders a little round the spot');
        expect((after.center.dx - before.center.dx).abs(), greaterThan((target.dx - before.center.dx).abs() * 0.4));
        await unmount(tester);
      });
    }

    testWidgets('a quick tap still makes it call; it is not picked up', (tester) async {
      final sounds = await pumpZoo(tester, [Creature.elephant]);
      sounds.played.clear();
      await tester.tap(find.bySemanticsLabel(Strings.resident(Creature.elephant.label)));
      await tester.pump();
      expect(sounds.played, isNot(contains(Sfx.boingHigh)));
      expect(sounds.played, isNotEmpty);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await unmount(tester);
    });
  });
}
