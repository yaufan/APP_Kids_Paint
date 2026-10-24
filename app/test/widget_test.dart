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
  testWidgets('home shows the three big picture buttons and no text to read', (tester) async {
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

    for (final label in [Strings.takePhoto, Strings.gallery, Strings.map]) {
      expect(find.bySemanticsLabel(label), findsOneWidget);
    }
    // Only the avatar emoji may appear; no words or letters.
    final words = RegExp(r'\p{L}', unicode: true);
    expect(find.byWidgetPredicate((w) => w is Text && words.hasMatch(w.data ?? '')), findsNothing);

    // Unmount so drift's stream queries shut down before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
  });
}
