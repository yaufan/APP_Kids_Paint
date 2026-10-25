import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';

void main() {
  testWidgets('home is the town map with picture buttons; the only words are the town name', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(ArtworkStore(Directory.systemTemp.createTempSync('kp'))),
      ],
      child: const KidsPaintApp(),
    ));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 100));

    for (final label in [Strings.takePhoto, Strings.album, Strings.templates]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    expect(find.byTooltip(Strings.parentMode), findsOneWidget);
    // Children do not need to read: besides the town's name, the postcard
    // count and the character's speech bubble, there is no text.
    final words = RegExp(r'\p{L}', unicode: true);
    final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').where(words.hasMatch).toSet();
    expect(texts, {Strings.townOf('小熊'), Strings.emptyTown});

    // Unmount so drift's stream queries shut down before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
