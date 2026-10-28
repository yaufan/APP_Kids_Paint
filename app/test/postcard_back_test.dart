import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/core/voice.dart';
import 'package:kids_paint/features/canvas/coloring.dart';

/// Keeps what was said.
class RecordingVoice implements Voice {
  final said = <String>[];

  @override
  Future<void> say(String text) async => said.add(text);

  @override
  Future<void> stop() async {}
}

/// The back of a postcard (0.18): a parent writes down what the child
/// said; turned over, the postcard shows it and reads it out.
void main() {
  late AppDatabase db;
  late ArtworkService service;
  late RecordingVoice voice;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = ArtworkStore(Directory.systemTemp.createTempSync('kp_back'));
    service = ArtworkService(ArtworkRepository(db), store);
    voice = RecordingVoice();
    await tester.runAsync(() => SettingsRepository(db).setWelcomed());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 3, 10)),
        systemSoundsProvider.overrideWithValue(const SilentSounds()),
        systemVoiceProvider.overrideWithValue(voice),
      ],
      child: const KidsPaintApp(),
    ));
  }

  Future<Artwork> sendDrawing(WidgetTester tester, PlaceKind kind) async => (await tester.runAsync(() async {
        final childId = (await ChildRepository(db).ensureDefault()).id;
        final art = await service.saveBlank(childId: childId);
        final page = await service.load(art.id);
        page.document.add(CrayonOp(1, 0xFFFF5E5B, 30, [(x: 150, y: 400), (x: 450, y: 400)]));
        await service.send(page, await PlaceRepository(db).defaultPlace(childId, kind));
        return ArtworkRepository(db).get(art.id);
      }))!;

  Future<void> settle(WidgetTester tester, Finder until) async {
    for (var i = 0; i < 60 && until.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(until, findsWidgets);
  }

  GoRouter router(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));

  testWidgets('a parent writes what the child said; the postcard turns over and reads it out', (tester) async {
    await pumpApp(tester);
    final art = await sendDrawing(tester, PlaceKind.park);
    const words = '這是我跟阿嬤在公園看到的鴨子';

    // Parent mode: write it on the back.
    router(tester).push('/parent/notes');
    await settle(tester, find.byKey(ValueKey('note-pick-${art.id}')));
    await tester.tap(find.byKey(ValueKey('note-pick-${art.id}')));
    await settle(tester, find.byKey(const ValueKey('note-field')));
    await tester.pump(const Duration(milliseconds: 500)); // the sheet slides up
    await tester.enterText(find.byKey(const ValueKey('note-field')), words);
    await tester.tap(find.byKey(const ValueKey('note-save')));
    await settle(tester, find.text(Strings.noteSaved));
    expect((await tester.runAsync(() => ArtworkRepository(db).get(art.id)))!.note, words);
    await settle(tester, find.bySemanticsLabel(RegExp(Strings.hasNote)));

    // The child turns it over while watching it colored again.
    router(tester).go('/replay/${art.id}');
    await settle(tester, find.byKey(const ValueKey('flip')));
    expect(find.byKey(const ValueKey('postcard-note')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('flip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text(words), findsOneWidget);
    expect(find.text(Strings.sentTo(PlaceKind.park.label)), findsOneWidget);
    expect(voice.said.last, words);
    expect(find.bySemanticsLabel(Strings.flipBack), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('flip')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const ValueKey('postcard-note')), findsNothing);
    expect(find.byKey(const ValueKey('replay-page')), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('without words on its back, a postcard does not turn over', (tester) async {
    await pumpApp(tester);
    final art = await sendDrawing(tester, PlaceKind.home);
    router(tester).go('/replay/${art.id}');
    await settle(tester, find.byKey(const ValueKey('replay-page')));
    expect(find.byKey(const ValueKey('flip')), findsNothing);
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
