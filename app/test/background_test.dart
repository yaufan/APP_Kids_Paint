import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/features/parent/parent_gate.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/core/town_time.dart';

/// 2.2: parents pick what plays in the background and how fast the town's day goes.
void main() {
  test('every background has its sound file', () {
    for (final a in Ambience.values) {
      expect(File('assets/sounds/${a.file}.wav').existsSync(), isTrue, reason: a.file);
    }
  });

  test('a picked background plays everywhere; "by place" keeps each place\'s own; quiet plays nothing', () {
    expect(Background.auto.instead(Ambience.bubbles), Ambience.bubbles);
    expect(Background.auto.instead(null), isNull, reason: 'the shop has none');
    expect(Background.musicBox.instead(Ambience.bubbles), Ambience.musicBox);
    expect(Background.waves.instead(null), Ambience.waves);
    expect(Background.quiet.instead(Ambience.birds), isNull);
    expect(Background.byName(null), Background.auto);
    expect(Background.byName('xylophone'), Background.xylophone);
  });

  testWidgets('parent mode: the choices are kept', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final settings = SettingsRepository(db);
    await tester.runAsync(() async {
      await settings.setWelcomed();
      await ChildRepository(db).ensureDefault();
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(ArtworkStore(Directory.systemTemp.createTempSync('kp_bg'))),
        systemSoundsProvider.overrideWithValue(const SilentSounds()),
      ],
      child: const KidsPaintApp(),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    ParentPass.grant();
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/parent');
    final fast = find.byKey(const ValueKey('cycle-fast'));
    for (var i = 0; i < 30 && fast.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(Strings.dayCycleName('lapse')), findsOneWidget);
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('cycle-lapse'))).selected, isTrue, reason: 'sped up by default');
    await tester.ensureVisible(fast);
    await tester.tap(fast);
    await tester.pump();

    // Further down, with the sounds.
    final waves = find.byKey(const ValueKey('background-waves'));
    await tester.scrollUntilVisible(waves, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(waves);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('background-auto'))).selected, isTrue);
    await tester.tap(waves);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(waves).selected, isTrue);
    final kept = await tester.runAsync(() async => (await settings.dayCycle(), await settings.background()));
    expect(kept, (DayCycle.fast, Background.waves));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
