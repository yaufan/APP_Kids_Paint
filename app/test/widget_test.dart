import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/festivals.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, DateTime now, {bool welcomed = true}) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    if (welcomed) await tester.runAsync(() => SettingsRepository(db).setWelcomed());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(ArtworkStore(Directory.systemTemp.createTempSync('kp'))),
        clockProvider.overrideWithValue(() => now),
      ],
      child: const KidsPaintApp(),
    ));
  }

  testWidgets('the first day starts by naming the town and picking a friend', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 25, 10), welcomed: false);
    for (var i = 0; i < 20 && find.text(Strings.welcome).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(Strings.welcome), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('town-name')), '小美');
    await tester.tap(find.byKey(const ValueKey('buddy-rabbit')));
    await tester.pump(const Duration(milliseconds: 300));
    // The button sits below the fold on the small test screen.
    await tester.ensureVisible(find.bySemanticsLabel(Strings.letsGo));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel(Strings.letsGo));
    for (var i = 0; i < 20 && find.text(Strings.townOf('小美')).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(Strings.townOf('小美')), findsOneWidget);
    expect(find.text(Strings.welcome), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('home is the town map with picture buttons; the only words are the town name', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 25, 10));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 100));

    for (final label in [Strings.takePhoto, Strings.album, Strings.blankPaper, Strings.places]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.byTooltip(Strings.parentMode), findsOneWidget);
    for (final place in [PlaceKind.zoo, PlaceKind.aquarium, PlaceKind.dinoPark, PlaceKind.transport]) {
      expect(find.bySemanticsLabel(Strings.enter(place.label)), findsOneWidget);
    }
    // Children do not need to read: besides the town's name, the postcard
    // count and the character's speech bubble, there is no text.
    final words = RegExp(r'\p{L}', unicode: true);
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').where(words.hasMatch).toSet();
    expect(texts, {Strings.townOf('小熊'), Strings.emptyTown});

    // Unmount so drift's stream queries shut down before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('on Christmas Eve night Gugu says good night, then brings a letter', (tester) async {
    await pumpApp(tester, DateTime(2026, 12, 24, 20));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(Strings.bedtime), findsOneWidget);
    // Whether the page was opened yet comes from the database.
    final letter = find.bySemanticsLabel(Strings.openLetter(Festival.christmas.label));
    for (var i = 0; i < 20 && letter.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(letter, findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(Strings.festivalLetter(Festival.christmas.label)), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('one button lists every place you can go into; one tap and the child is inside', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, DateTime(2026, 10, 25, 10));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.bySemanticsLabel(Strings.places));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    for (final h in Habitat.values) {
      expect(find.bySemanticsLabel(Strings.goTo(h.label)), findsOneWidget, reason: h.label);
    }
    await tester.tap(find.bySemanticsLabel(Strings.goTo(Habitat.polar.label)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel(Strings.drawNew(Habitat.polar.label, residents: Habitat.polar.residents)), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });

  testWidgets('the zoo opens from the town and invites the child to color an animal', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 25, 10));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.bySemanticsLabel(Strings.enter(PlaceKind.zoo.label)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(Strings.sceneEmpty(PlaceKind.zoo.label)), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(Strings.drawNew(PlaceKind.zoo.label)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    for (final c in Habitat.zoo.creatures) {
      expect(find.bySemanticsLabel(Strings.drawCreature(c.label)), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
