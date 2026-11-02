import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/canvas/page_image.dart';

/// 2.1: a finger colors the moment it lands, two fingers zoom, and the
/// magnifier looks closely at a spot.
void main() {
  group('pageFit', () {
    test('a page without lines, or with lines all over, is shown whole', () {
      expect(pageFit(Uint8List(60 * 80)..fillRange(0, 60 * 80, 255), 60, 80), const Rect.fromLTWH(0, 0, 60, 80));
      expect(pageFit(Uint8List(60 * 80), 60, 80), const Rect.fromLTWH(0, 0, 60, 80));
    });

    test('a small drawing is shown close up, in the page\'s shape and on the page', () {
      final lines = Uint8List(600 * 800)..fillRange(0, 600 * 800, 255);
      for (var y = 300; y < 500; y++) {
        for (var x = 200; x < 400; x++) {
          if (x == 200 || x == 399 || y == 300 || y == 499) lines[y * 600 + x] = 0;
        }
      }
      final fit = pageFit(lines, 600, 800);
      expect(fit.width / fit.height, closeTo(600 / 800, 1e-9));
      expect(fit.contains(const Offset(200, 300)) && fit.contains(const Offset(399, 499)), isTrue);
      expect(fit.width, lessThan(600 / 1.02));
      expect(fit.left >= 0 && fit.top >= 0 && fit.right <= 600 && fit.bottom <= 800, isTrue);

      // Near an edge it slides back onto the page.
      final corner = Uint8List(600 * 800)..fillRange(0, 600 * 800, 255);
      for (var x = 0; x < 120; x++) {
        corner[10 * 600 + x] = 0;
      }
      final near = pageFit(corner, 600, 800);
      expect(near.left, 0);
      expect(near.top, 0);
    });
  });

  group('the canvas', () {
    late AppDatabase db;
    late ArtworkService service;
    late int artworkId;

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = ArtworkStore(Directory.systemTemp.createTempSync('kp_touch'));
      service = ArtworkService(ArtworkRepository(db), store);
      artworkId = (await tester.runAsync(() async {
        await SettingsRepository(db).setWelcomed();
        final childId = (await ChildRepository(db).ensureDefault()).id;
        final png = await File('assets/pages/elephant.png').readAsBytes();
        return (await service.saveTemplate(childId: childId, template: 'elephant', png: png)).id;
      }))!;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          artworkStoreProvider.overrideWithValue(store),
          clockProvider.overrideWithValue(() => DateTime(2026, 11, 2, 10)),
          systemSoundsProvider.overrideWithValue(const SilentSounds()),
        ],
        child: const KidsPaintApp(),
      ));
      await tester.pump();
      GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/canvas/$artworkId');
      final page = find.byKey(const ValueKey('page'));
      for (var i = 0; i < 100 && page.evaluate().isEmpty; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(page, findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
    }

    /// What the page holds now, as saved (the autosave's file writes are
    /// let through first).
    Future<List<PaintOp>> saved(WidgetTester tester) async {
      for (var i = 0; i < 20; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump();
      }
      return (await tester.runAsync(() async => (await service.load(artworkId)).document.ops))!;
    }

    Future<void> unmount(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    }

    Rect pageRect(WidgetTester tester) => tester.getRect(find.byKey(const ValueKey('page')));

    testWidgets('the bucket fills the moment a finger lands', (tester) async {
      await open(tester);
      final page = pageRect(tester);
      final finger = await tester.startGesture(page.topLeft + Offset(page.width * 0.08, page.height * 0.08));
      await tester.pump();
      expect((await saved(tester)).single, isA<FillOp>(), reason: 'filled before the finger lifts');
      await finger.up();
      await tester.pump();
      expect((await saved(tester)).length, 1);
      await unmount(tester);
    });

    testWidgets('a short little stroke draws, from where the finger landed', (tester) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel(Strings.crayon));
      await tester.pump(const Duration(milliseconds: 300));
      final page = pageRect(tester);
      final start = page.topLeft + Offset(page.width * 0.08, page.height * 0.5);
      final finger = await tester.startGesture(start);
      await tester.pump();
      // Shorter than the 36 points the old pan gesture waited for.
      for (var i = 0; i < 4; i++) {
        await finger.moveBy(const Offset(5, 2));
        await tester.pump();
      }
      await finger.up();
      await tester.pump();
      final stroke = (await saved(tester)).single as CrayonOp;
      expect(stroke.points.length, 5, reason: 'the landing point and every move');
      await unmount(tester);
    });

    testWidgets('two fingers zoom in and leave no mark; the magnifier goes back out', (tester) async {
      await open(tester);
      expect(find.bySemanticsLabel(Strings.zoomIn), findsOneWidget);
      final page = pageRect(tester);
      final a = await tester.startGesture(page.center - const Offset(20, 0), pointer: 1);
      await tester.pump(const Duration(milliseconds: 50));
      final b = await tester.startGesture(page.center + const Offset(20, 0), pointer: 2);
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await a.moveBy(const Offset(-15, 0));
        await b.moveBy(const Offset(15, 0));
        await tester.pump();
      }
      await a.up();
      await b.up();
      await tester.pump();
      expect(await saved(tester), isEmpty, reason: 'the first finger\'s fill was the start of a pinch');
      expect(find.bySemanticsLabel(Strings.zoomOut), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(Strings.zoomOut));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.bySemanticsLabel(Strings.zoomIn), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the magnifier zooms into the next spot touched, without coloring it', (tester) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel(Strings.zoomIn));
      await tester.pump();
      expect(find.text(Strings.zoomHint), findsOneWidget);
      final page = pageRect(tester);
      await tester.tapAt(page.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(Strings.zoomHint), findsNothing);
      expect(find.bySemanticsLabel(Strings.zoomOut), findsOneWidget);
      expect(await saved(tester), isEmpty);

      // Zoomed in, a finger colors as before.
      await tester.tapAt(page.topLeft + Offset(page.width * 0.1, page.height * 0.1));
      await tester.pump();
      expect((await saved(tester)).single, isA<FillOp>());
      await unmount(tester);
    });
  });
}
