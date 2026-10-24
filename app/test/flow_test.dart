import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart' show avatars;
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/capture/capture_screen.dart';
import 'package:kids_paint/features/lineart/simple_engine.dart';

/// Walks through the app the way a child (and then a parent) would, on a
/// simulated phone, and saves a screenshot of every step to
/// `build/screenshots/`. Camera and photo picker are the only parts skipped:
/// the test hands the photo over directly.
void main() {
  final shotKey = GlobalKey();

  Future<void> loadFonts() async {
    // Real fonts instead of the test font's boxes, when they are available.
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
    final fonts = {
      'MaterialIcons': ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'],
      'Roboto': ['/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc'], // Chinese text
      'Noto Color Emoji': ['/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf'], // avatars
    };
    for (final MapEntry(key: family, value: paths) in fonts.entries) {
      final loader = FontLoader(family);
      for (final path in paths.where((p) => File(p).existsSync())) {
        loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
      }
      await loader.load();
    }
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

  Future<void> idle(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    final boundary = shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/screenshots/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  int answerParentGate(WidgetTester tester) {
    const digits = '零一二三四五六七八九';
    final question = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((s) => s.startsWith('請輸入「'));
    final numbers = RegExp('「(.)」').allMatches(question).map((m) => digits.indexOf(m.group(1)!));
    return numbers.reduce((a, b) => a + b);
  }

  testWidgets('a child makes a coloring page, colors it and finds it in the gallery', (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = const Size(1080, 2340); // a common Android phone
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final storeDir = Directory.systemTemp.createTempSync('kids_paint_flow');
    addTearDown(() => storeDir.deleteSync(recursive: true));
    final photo = File('test/assets/coffee.jpg').readAsBytesSync();

    await tester.pumpWidget(RepaintBoundary(
      key: shotKey,
      child: ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          artworkStoreProvider.overrideWithValue(ArtworkStore(storeDir)),
          lineArtEngineProvider.overrideWithValue(const SimpleLineArtEngine(size: 768)),
        ],
        child: const KidsPaintApp(),
      ),
    ));

    // 1. Home: three picture buttons.
    await waitFor(tester, find.text(avatars.first));
    await shot(tester, '01_home');

    // 2. Camera or album.
    await tester.tap(find.bySemanticsLabel(Strings.takePhoto));
    await waitFor(tester, find.bySemanticsLabel(Strings.camera));
    await shot(tester, '02_capture');

    // 3. The photo comes back from the camera (simulated) -> two styles.
    GoRouter.of(tester.element(find.byType(CaptureScreen))).push('/styles', extra: photo);
    await waitFor(tester, find.bySemanticsLabel(Strings.realistic));
    await idle(tester);
    await shot(tester, '03_styles');

    // 4. Pick the realistic page -> canvas.
    await tester.tap(find.bySemanticsLabel(Strings.realistic));
    await waitFor(tester, find.bySemanticsLabel(Strings.bucket));
    await idle(tester);
    await shot(tester, '04_canvas_blank');

    // 5. Bucket-fill a few areas in different colors, then a crayon stroke.
    final canvas = tester.getRect(find.byType(CustomPaint).last);
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
    await shot(tester, '05_canvas_colored');

    // 6. Home saves the picture; it shows up in the gallery.
    await tester.tap(find.bySemanticsLabel(Strings.home));
    await waitFor(tester, find.bySemanticsLabel(Strings.gallery));
    await tester.tap(find.bySemanticsLabel(Strings.gallery));
    await waitFor(tester, find.byType(Image));
    await idle(tester);
    await shot(tester, '06_gallery');

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
    await shot(tester, '07_parent_gate');
    await tester.enterText(find.byType(TextField), '${answerParentGate(tester)}');
    await tester.tap(find.text(Strings.confirm));
    await waitFor(tester, find.text(Strings.dailyLimit));
    await idle(tester, 500);
    await shot(tester, '08_parent_mode');

    // Unmount so drift's stream queries shut down before the test ends.
    await tester.pumpWidget(const SizedBox());
    await idle(tester, 200);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

