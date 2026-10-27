import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/play_time.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/core/voice.dart';
import 'package:kids_paint/features/parent/parent_gate.dart';
import 'package:kids_paint/features/rest/rest_curtain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nearly over three minutes before the limit, over at it, far over ten minutes after', () {
    PlayTime at(int minutes) => PlayTime(played: Duration(minutes: minutes), allowed: const Duration(minutes: 30));
    expect([at(20).almostOver, at(20).over], [false, false]);
    expect([at(27).almostOver, at(27).over], [true, false]);
    expect([at(30).almostOver, at(30).over, at(30).wayOver], [false, true, false]);
    expect(at(40).wayOver, isTrue);
    expect(const PlayTime(played: Duration(hours: 5), allowed: null).over, isFalse, reason: 'no limit');
  });

  test('a picture being made holds the rest screen back', () {
    expect(['/canvas/3', '/send/3', '/sent/3'].every(RestCurtain.busy), isTrue);
    expect(['/', '/album', '/scene/zoo', '/capture'].any(RestCurtain.busy), isFalse);
  });

  group('the play clock', () {
    late AppDatabase db;
    var now = DateTime(2026, 10, 27, 16);

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<ProviderContainer> open() async {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ]);
      container.read(playTimeProvider);
      await container.read(playTimeProvider.notifier).reload();
      return container;
    }

    test('adds up the day, remembers it after closing, and a parent can give more', () async {
      final clock = await open();
      final play = clock.read(playTimeProvider.notifier);
      expect(clock.read(playTimeProvider)!.played, Duration.zero);
      await play.add(const Duration(minutes: 27, seconds: 30));
      expect(clock.read(playTimeProvider)!.almostOver, isTrue);
      await play.add(const Duration(minutes: 3));
      expect(clock.read(playTimeProvider)!.over, isTrue);
      await play.extend(10);
      expect(clock.read(playTimeProvider)!.left, const Duration(minutes: 9, seconds: 30));
      clock.dispose();

      final reopened = await open();
      expect(reopened.read(playTimeProvider)!.played, const Duration(minutes: 30, seconds: 30));
      expect(reopened.read(playTimeProvider)!.allowed, const Duration(minutes: 40));
      reopened.dispose();
    });

    test('a new day starts from nothing', () async {
      final clock = await open();
      await clock.read(playTimeProvider.notifier).add(const Duration(minutes: 45));
      expect(clock.read(playTimeProvider)!.over, isTrue);
      now = now.add(const Duration(days: 1));
      await clock.read(playTimeProvider.notifier).add(Duration.zero);
      expect(clock.read(playTimeProvider)!.played, Duration.zero);
      expect(clock.read(playTimeProvider)!.over, isFalse);
      clock.dispose();
    });

    test('no limit means it is never over', () async {
      await SettingsRepository(db).setDailyMinutes(SettingsRepository.noLimit);
      final clock = await open();
      await clock.read(playTimeProvider.notifier).add(const Duration(hours: 3));
      expect(clock.read(playTimeProvider)!.allowed, isNull);
      expect(clock.read(playTimeProvider)!.over, isFalse);
      clock.dispose();
    });
  });

  testWidgets('when time is up the pigeon falls asleep over the town; more time lifts it', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime(2026, 10, 27, 17);
    await tester.runAsync(() async {
      final settings = SettingsRepository(db);
      await settings.setWelcomed();
      await settings.setDailyMinutes(15);
      await settings.setPlayOn(dayOf(now), seconds: 15 * 60, extraMinutes: 0);
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(ArtworkStore(Directory.systemTemp.createTempSync('kp'))),
        clockProvider.overrideWithValue(() => now),
        systemVoiceProvider.overrideWithValue(const SilentVoice()),
      ],
      child: const KidsPaintApp(),
    ));
    final rest = find.byKey(const ValueKey('rest-screen'));
    for (var i = 0; i < 20 && rest.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(rest, findsOneWidget);
    expect(find.text(Strings.restBody), findsOneWidget);
    expect(find.text(Strings.restTitle(0)), findsOneWidget);

    // A grown-up's way out goes through the parent gate.
    await tester.tap(find.byTooltip(Strings.parentMode).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(Strings.callParent), findsOneWidget);
    expect(rest, findsNothing, reason: 'the curtain steps aside for the gate');
    Navigator.of(tester.element(find.byType(ParentGatePage))).pop(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(rest, findsOneWidget, reason: 'no answer, still resting');

    // After a right answer the parent gives ten more minutes.
    final container = ProviderScope.containerOf(tester.element(rest));
    await tester.runAsync(() => container.read(playTimeProvider.notifier).extend(10));
    await tester.pump(const Duration(milliseconds: 300));
    expect(rest, findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
