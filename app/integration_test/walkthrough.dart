import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/capture/capture_screen.dart';
import 'package:kids_paint/features/lineart/simple_engine.dart';

/// Captures the screen under [name].
typedef Shot = Future<void> Function(String name);

/// Wraps the app so a screenshot can be taken from the widget tree.
final walkthroughKey = GlobalKey();

/// The whole app as a child (and then a parent) uses it, with a screenshot
/// of every step. Shared by `test/flow_test.dart` (headless, phone-sized) and
/// `integration_test/app_flow_test.dart` (iPhone/iPad simulators). Only the
/// camera is skipped: [photo] is handed over as if it had just been taken.
Future<void> runWalkthrough(WidgetTester tester, {required Uint8List photo, required Shot shot}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final storeDir = await tester.runAsync(() => Directory.systemTemp.createTemp('kids_paint_flow'));

  await tester.pumpWidget(RepaintBoundary(
    key: walkthroughKey,
    child: ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(ArtworkStore(storeDir!)),
        lineArtEngineProvider.overrideWithValue(const SimpleLineArtEngine(size: 768)),
      ],
      child: const KidsPaintApp(),
    ),
  ));

  // 1. Home: big picture buttons.
  await waitFor(tester, find.bySemanticsLabel(Strings.takePhoto));
  await idle(tester);
  await shot('01_home');

  // 2. Camera or album.
  await tester.tap(find.bySemanticsLabel(Strings.takePhoto));
  await waitFor(tester, find.bySemanticsLabel(Strings.camera));
  await idle(tester, 800);
  await shot('02_capture');

  // 3. The photo comes back from the camera -> both styles side by side.
  GoRouter.of(tester.element(find.byType(CaptureScreen))).push('/styles', extra: photo);
  await waitFor(tester, find.bySemanticsLabel(Strings.realistic));
  await idle(tester);
  await shot('03_styles');

  // 4. Pick the realistic page -> canvas.
  await tester.tap(find.bySemanticsLabel(Strings.realistic));
  await waitFor(tester, find.bySemanticsLabel(Strings.bucket));
  await idle(tester);
  await shot('04_canvas_blank');

  // 5. Bucket-fill a few areas in different colors, then a crayon stroke.
  final canvas = tester.getRect(find.byKey(const ValueKey('page')));
  for (final (color, dx, dy) in [
    (kidPalette[0], 0.50, 0.30),
    (kidPalette[2], 0.50, 0.55),
    (kidPalette[5], 0.10, 0.10),
    (kidPalette[3], 0.85, 0.85),
  ]) {
    await tester.tap(find.byKey(ValueKey('swatch-$color')));
    await tester.pump();
    await tester.tapAt(canvas.topLeft + Offset(canvas.width * dx, canvas.height * dy));
    await idle(tester, 500);
  }
  await tester.tap(find.bySemanticsLabel(Strings.crayon));
  await tester.tap(find.byKey(ValueKey('swatch-${kidPalette[7]}')));
  await tester.pump();
  final start = canvas.topLeft + Offset(canvas.width * 0.3, canvas.height * 0.8);
  final gesture = await tester.startGesture(start);
  for (var i = 1; i <= 12; i++) {
    await gesture.moveTo(start + Offset(i * canvas.width * 0.03, (i.isEven ? -1 : 1) * 12));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await idle(tester);
  await shot('05_canvas_colored');

  // 6. Home saves the picture; it shows up in the gallery.
  await tester.tap(find.bySemanticsLabel(Strings.home));
  await waitFor(tester, find.bySemanticsLabel(Strings.gallery));
  await idle(tester, 800); // the buttons pop in one by one
  await tester.tap(find.bySemanticsLabel(Strings.gallery));
  await waitFor(tester, find.descendant(of: find.byType(GridView), matching: find.byType(Image)));
  await idle(tester);
  await shot('06_gallery');

  final saved = await tester.runAsync(() => db.select(db.artworks).get());
  expect(saved, hasLength(1));
  expect(saved!.single.isCompleted, isTrue);
  expect(File('${storeDir.path}/${saved.single.folder}/colored.png').existsSync(), isTrue);

  // 7. Parent gate, then parent mode.
  await tester.tap(find.bySemanticsLabel(Strings.home));
  await waitFor(tester, find.byTooltip(Strings.parentMode));
  await tester.tap(find.byTooltip(Strings.parentMode));
  await waitFor(tester, find.text(Strings.parentGateTitle));
  await idle(tester, 500); // let the dialog finish fading in
  await shot('07_parent_gate');
  await tester.enterText(find.byType(TextField), '${answerParentGate(tester)}');
  await tester.tap(find.text(Strings.confirm));
  await waitFor(tester, find.text(Strings.dailyLimit));
  await idle(tester, 500);
  await shot('08_parent_mode');

  // Unmount so drift's stream queries shut down before the test ends.
  await tester.pumpWidget(const SizedBox());
  await idle(tester, 200);
  await tester.runAsync(() async {
    await db.close();
    await storeDir.delete(recursive: true);
  });
}

/// Lets real async work (isolates, files, image decoding) run until [until] shows up.
Future<void> waitFor(WidgetTester tester, Finder until, {int seconds = 60}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    if (until.evaluate().isNotEmpty) return;
  }
  fail('timed out waiting for $until');
}

/// Lets animations and background work settle for about [ms] milliseconds.
Future<void> idle(WidgetTester tester, [int ms = 1500]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Reads the parent gate question ("七" 加 "八") and returns the sum.
int answerParentGate(WidgetTester tester) {
  const digits = '零一二三四五六七八九';
  final question = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .firstWhere((s) => s.startsWith('請輸入「'));
  final numbers = RegExp('「(.)」').allMatches(question).map((m) => digits.indexOf(m.group(1)!));
  return numbers.reduce((a, b) => a + b);
}

/// A drawn "photo" of a cup on a saucer, for devices where test files are
/// not available.
Uint8List syntheticPhoto() {
  final image = img.Image(width: 900, height: 700)..clear(img.ColorRgb8(196, 226, 240));
  img.fillRect(image, x1: 0, y1: 470, x2: 900, y2: 700, color: img.ColorRgb8(170, 120, 80));
  img.fillCircle(image, x: 760, y: 120, radius: 70, color: img.ColorRgb8(255, 210, 60));
  img.fillCircle(image, x: 450, y: 520, radius: 230, color: img.ColorRgb8(240, 240, 235));
  img.fillRect(image, x1: 300, y1: 260, x2: 600, y2: 520, color: img.ColorRgb8(215, 60, 50), radius: 60);
  img.fillCircle(image, x: 450, y: 270, radius: 150, color: img.ColorRgb8(235, 235, 230));
  img.fillCircle(image, x: 450, y: 275, radius: 120, color: img.ColorRgb8(120, 70, 40));
  img.fillCircle(image, x: 640, y: 390, radius: 60, color: img.ColorRgb8(215, 60, 50));
  img.fillCircle(image, x: 640, y: 390, radius: 30, color: img.ColorRgb8(240, 240, 235));
  return img.encodeJpg(image, quality: 90);
}
