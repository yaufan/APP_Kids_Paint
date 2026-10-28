import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/town/place_sheet.dart';
import 'package:kids_paint/features/town/town_layout_data.dart';

/// Keeps what was played.
class RecordingSounds implements Sounds {
  final played = <Sfx>[];

  @override
  set enabled(bool on) {}

  @override
  void play(Sfx sfx) => played.add(sfx);

  @override
  void hold(Object owner, Ambience? ambience) {}

  @override
  void release(Object owner) {}
}

/// The town you can poke (0.18): the train drives off, ducks quack, cars
/// honk, 101 sets off fireworks, a cloud rains a little.
void main() {
  late AppDatabase db;
  late ArtworkService service;
  late RecordingSounds sounds;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = ArtworkStore(Directory.systemTemp.createTempSync('kp_toys'));
    service = ArtworkService(ArtworkRepository(db), store);
    sounds = RecordingSounds();
    await tester.runAsync(() => SettingsRepository(db).setWelcomed());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 3, 10)),
        systemSoundsProvider.overrideWithValue(sounds),
      ],
      child: const KidsPaintApp(),
    ));
  }

  Future<void> sendDrawing(WidgetTester tester, PlaceKind kind) async => tester.runAsync(() async {
        final childId = (await ChildRepository(db).ensureDefault()).id;
        final art = await service.saveBlank(childId: childId);
        final page = await service.load(art.id);
        page.document.add(CrayonOp(1, 0xFFFF5E5B, 30, [(x: 150, y: 400), (x: 450, y: 400)]));
        await service.send(page, await PlaceRepository(db).defaultPlace(childId, kind));
      });

  Future<void> settle(WidgetTester tester, Finder until) async {
    for (var i = 0; i < 60 && until.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(until, findsWidgets);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  Finder sprite(String name) => find.byKey(ValueKey('toy-$name'));
  Finder poke(String name) => find.byKey(ValueKey('poke-$name'));

  testWidgets('the train drives off to the right and comes back round to the station', (tester) async {
    await pumpApp(tester);
    await settle(tester, poke('mrt'));
    final home = tester.getRect(sprite('mrt'));
    await tester.tap(poke('mrt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
    expect(tester.getRect(sprite('mrt')).left, greaterThan(home.left + 150), reason: 'on its way');
    await tester.pump(const Duration(milliseconds: 3600));
    expect(tester.getRect(sprite('mrt')).left, closeTo(home.left, 0.5), reason: 'back again');
    expect(sounds.played, contains(Sfx.toot));
    await unmount(tester);
  });

  testWidgets('a duck bobs and quacks; cars honk; 101 and the clouds make their sounds', (tester) async {
    await pumpApp(tester);
    await settle(tester, poke('duckRiver'));
    final duck = tester.getRect(sprite('duckRiver'));
    // Its left side: the other duck swims close by, on top.
    await tester.tapAt(tester.getRect(poke('duckRiver')).centerLeft + const Offset(5, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getRect(sprite('duckRiver')).top, lessThan(duck.top - 1), reason: 'it bobs up');
    expect(sounds.played.last, Sfx.quack);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getRect(sprite('duckRiver')).top, closeTo(duck.top, 0.5));

    await tester.tap(poke('car0'));
    await tester.pump();
    expect(sounds.played.last, Sfx.honk);
    await tester.tap(poke('tower'));
    await tester.pump();
    expect(sounds.played.last, Sfx.firework);
    await tester.tap(poke('cloud'));
    await tester.pump();
    expect(sounds.played.last, Sfx.drizzle);
    expect(find.bySemanticsLabel(Strings.toy('tower')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await unmount(tester);
  });

  testWidgets("the park's ducks come with the park", (tester) async {
    await pumpApp(tester);
    await settle(tester, poke('duckRiver'));
    expect(poke('duckPark'), findsNothing, reason: 'still an empty lot');
    await sendDrawing(tester, PlaceKind.park);
    await settle(tester, poke('duckPark'));
    await tester.tap(poke('duckPark'));
    await tester.pump();
    expect(sounds.played.last, Sfx.quack);
    await tester.pump(const Duration(seconds: 2));
    await unmount(tester);
  });

  testWidgets('around a pin, a toy there gets the tap; elsewhere the pin does', (tester) async {
    await pumpApp(tester);
    await sendDrawing(tester, PlaceKind.home);
    final pin = find.bySemanticsLabel(Strings.pinLabel(PlaceKind.home.label, 1));
    await settle(tester, pin);
    // The pin takes taps 40 points either side of it and 20 above and below.
    final box = tester.getRect(pin);
    final train = tester.getRect(poke('mrt'));
    final trainAt = tester.getRect(sprite('mrt'));
    final onTrain = Offset(box.right - 15, train.center.dy);
    expect(box.contains(onTrain) && train.contains(onTrain), isTrue, reason: "the train runs under home's pin");
    await tester.tapAt(onTrain);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(tester.getRect(sprite('mrt')).left, greaterThan(trainAt.left + 50), reason: 'the train went');
    expect(find.byType(PlaceSheet), findsNothing);

    // Below the train, beside the pin: nothing else there, so the pin.
    final beside = Offset(box.left + 10, box.bottom - 8);
    for (final toy in townToys.keys) {
      if (poke(toy).evaluate().isNotEmpty) expect(tester.getRect(poke(toy)).contains(beside), isFalse, reason: toy);
    }
    await tester.tapAt(beside);
    await settle(tester, find.byType(PlaceSheet));
    await tester.pump(const Duration(seconds: 5));
    await unmount(tester);
  });
}
