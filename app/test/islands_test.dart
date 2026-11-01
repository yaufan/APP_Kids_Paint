import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/town/place_sheet.dart';
import 'package:kids_paint/features/town/island_layout_data.dart';
import 'package:kids_paint/features/town/town_map.dart';

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

/// The town as floating islands (2.0): tap an island to go in or see its
/// postcards; the islands float, and what is on them floats along; poke
/// the train, a duck, the boat, the balloon, 101 and the clouds (0.18).
void main() {
  late AppDatabase db;
  late ArtworkService service;
  late RecordingSounds sounds;

  // A screen as big as the world, so every island is on it.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = Size(islandWorld.width * 2, islandWorld.height * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = ArtworkStore(Directory.systemTemp.createTempSync('kp_islands'));
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
  Finder island(String name) => find.byKey(ValueKey('island-$name'));

  testWidgets('the train goes across its bridge to home, and comes back', (tester) async {
    await pumpApp(tester);
    await settle(tester, poke('train'));
    final stop = tester.getRect(sprite('train'));
    await tester.tap(poke('train'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2300));
    final there = tester.getRect(sprite('train'));
    expect(there.left, lessThan(stop.left - 80), reason: 'over by home');
    expect((there.center - islandRail.last * (stop.width / islandToys['train']!.art!.width)).distance, lessThan(80));
    await tester.pump(const Duration(milliseconds: 3200));
    expect(tester.getRect(sprite('train')).left, closeTo(stop.left, 0.5), reason: 'back at its stop');
    expect(sounds.played, contains(Sfx.toot));
    await unmount(tester);
  });

  testWidgets('the balloon rises and comes down; 101 and the clouds make their sounds; the boat sails round', (tester) async {
    await pumpApp(tester);
    // A postcard home, so no word bubble covers the sea.
    await sendDrawing(tester, PlaceKind.home);
    await settle(tester, find.bySemanticsLabel(Strings.pinLabel(PlaceKind.home.label, 1)));
    await settle(tester, poke('balloon'));
    final balloon = tester.getRect(sprite('balloon'));
    await tester.tap(poke('balloon'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2100));
    expect(tester.getRect(sprite('balloon')).top, lessThan(balloon.top - 60), reason: 'up in the sky');
    expect(sounds.played.last, Sfx.swish);
    await tester.pump(const Duration(milliseconds: 2400));
    expect(tester.getRect(sprite('balloon')).top, closeTo(balloon.top, 0.5));

    await tester.tap(poke('tower'));
    await tester.pump();
    expect(sounds.played.last, Sfx.firework);
    await tester.tap(poke('cloud3'));
    await tester.pump();
    expect(sounds.played.last, Sfx.drizzle);
    expect(find.bySemanticsLabel(Strings.toy('tower')), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));

    // The sea is under the buttons: up a little first.
    await tester.drag(find.byType(InteractiveViewer), const Offset(0, -220));
    await tester.pump(const Duration(milliseconds: 300));
    final boat = tester.getRect(sprite('boat'));
    await tester.tap(poke('boat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2400));
    expect(tester.getRect(sprite('boat')).left, isNot(closeTo(boat.left, 40)), reason: 'sailing');
    expect(sounds.played.last, Sfx.toot);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.getRect(sprite('boat')).left, closeTo(boat.left, 0.5), reason: 'back again');
    await tester.tap(poke('duckSea'));
    await tester.pump();
    expect(sounds.played.last, Sfx.quack);
    await tester.pump(const Duration(seconds: 2));
    await unmount(tester);
  });

  testWidgets("the park's ducks come with the park, and bob when poked", (tester) async {
    await pumpApp(tester);
    await settle(tester, poke('train'));
    expect(poke('duckPark'), findsNothing, reason: 'the park island is still bare');
    await sendDrawing(tester, PlaceKind.park);
    await settle(tester, poke('duckPark'));
    await tester.tap(poke('duckPark'));
    await tester.pump();
    final bob = tester.getRect(sprite('duckPark')).top;
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getRect(sprite('duckPark')).top, lessThan(bob - 1), reason: 'it bobs up');
    expect(sounds.played.last, Sfx.quack);
    await tester.pump(const Duration(seconds: 2));
    await unmount(tester);
  });

  testWidgets('an island takes you in, shows its postcards, or says nothing is there yet', (tester) async {
    await pumpApp(tester);
    await sendDrawing(tester, PlaceKind.home);
    await settle(tester, find.bySemanticsLabel(Strings.pinLabel(PlaceKind.home.label, 1)));

    // School: bare until a postcard goes there.
    expect(find.bySemanticsLabel('${PlaceKind.school.label}，還沒畫過'), findsOneWidget);
    await tester.tap(island('school'));
    await tester.pump();
    expect(find.text(Strings.emptyLot), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    // Home: its postcards.
    await tester.tap(island('home'));
    await settle(tester, find.byType(PlaceSheet));
    await tester.tapAt(const Offset(20, 20));
    await tester.pump(const Duration(seconds: 1));

    // The city island: into the shop (on its left; 101 in the middle is a toy).
    expect(find.bySemanticsLabel(Strings.enter(PlaceKind.shop.label)), findsOneWidget);
    final city = tester.getRect(island('city'));
    await tester.tapAt(Offset(city.left + 50, city.top + city.height * 0.6));
    await settle(tester, find.bySemanticsLabel(Strings.drawNew(PlaceKind.shop.label, residents: Residents.goods)));
    await unmount(tester);
  });

  testWidgets('the islands float, and their pins float with them', (tester) async {
    await pumpApp(tester);
    await sendDrawing(tester, PlaceKind.home);
    final pin = find.bySemanticsLabel(Strings.pinLabel(PlaceKind.home.label, 1));
    await settle(tester, pin);
    final pinAt = tester.getRect(pin).top, islandAt = tester.getRect(island('home')).top;
    await tester.pump(const Duration(seconds: 2));
    final moved = tester.getRect(island('home')).top - islandAt;
    expect(moved.abs(), greaterThan(1), reason: 'it floats');
    expect(tester.getRect(pin).top - pinAt, closeTo(moved, 0.5), reason: 'the pin goes with it');
    expect(islandBob(null, 0.3), 0, reason: 'nothing floats off the islands');
    await unmount(tester);
  });
}
