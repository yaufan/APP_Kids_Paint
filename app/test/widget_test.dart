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
import 'package:kids_paint/core/storage/artwork_store.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, DateTime now) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(ArtworkStore(Directory.systemTemp.createTempSync('kp'))),
        clockProvider.overrideWithValue(() => now),
      ],
      child: const KidsPaintApp(),
    ));
  }

  testWidgets('home is the town map with picture buttons; the only words are the town name', (tester) async {
    await pumpApp(tester, DateTime(2026, 10, 25, 10));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 100));

    for (final label in [Strings.takePhoto, Strings.album, Strings.blankPaper]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.byTooltip(Strings.parentMode), findsOneWidget);
    for (final place in [PlaceKind.zoo, PlaceKind.aquarium]) {
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
    expect(find.bySemanticsLabel(Strings.openLetter(Festival.christmas.label)), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text(Strings.festivalLetter(Festival.christmas.label)), findsOneWidget);

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
