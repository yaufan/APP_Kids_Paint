import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:kids_paint/app/app.dart';
import 'package:kids_paint/app/strings.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/capture/paper_photo.dart';

/// A drawing on paper, photographed (0.18): the sheet out of the table,
/// the paper see-through, the drawing kept.
void main() {
  // test/assets/paper_drawing.jpg: a cow drawn on an off-white sheet, on a
  // wooden table, lit from the top left, the phone's shadow at the bottom.
  final photo = File('test/assets/paper_drawing.jpg').readAsBytesSync();

  test('the table and the paper go, the drawing stays, cropped close', () {
    final drawing = paperDrawing(photo)!;
    final out = img.decodePng(drawing.png)!;
    if (Platform.environment['DUMP_PAPER'] case final path?) File(path).writeAsBytesSync(drawing.png);
    expect((out.width, out.height), (drawing.width, drawing.height));
    // The cow is drawn about 300 x 470 of the 1200 x 900 photo: at 800
    // across, about 200 x 315, and a little paper around it.
    expect(out.width, inInclusiveRange(180, 260));
    expect(out.height, inInclusiveRange(290, 370));
    // Its corners are paper: see-through (at most a breath of the shadow).
    for (final (x, y) in [(2, 2), (out.width - 3, 2), (2, out.height - 3), (out.width - 3, out.height - 3)]) {
      expect(out.getPixel(x, y).a, lessThan(40), reason: 'corner $x,$y');
    }
    // The outline is dark and solid; the pink nose stays pink.
    var dark = 0, pink = 0, see = 0;
    for (final p in out) {
      if (p.a < 30) see++;
      if (p.a > 200 && p.r < 80 && p.g < 80 && p.b < 80) dark++;
      if (p.a > 200 && p.r > 200 && p.g < 170 && p.b < 190 && p.r - p.g > 50) pink++;
    }
    final n = out.width * out.height;
    expect(dark / n, greaterThan(0.04), reason: 'the lines');
    expect(pink / n, greaterThan(0.01), reason: 'the nose and cheeks');
    expect(see / n, greaterThan(0.3), reason: 'the paper around and inside it');
  });

  testWidgets('photographed, a drawing on paper lands on the canvas to color, and undo leaves it there', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = ArtworkStore(Directory.systemTemp.createTempSync('kp_paper'));
    final service = ArtworkService(ArtworkRepository(db), store);
    await tester.runAsync(() => SettingsRepository(db).setWelcomed());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(store),
        systemSoundsProvider.overrideWithValue(const SilentSounds()),
      ],
      child: const KidsPaintApp(),
    ));
    await tester.pump();
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/paper', extra: photo);
    final page = find.byKey(const ValueKey('page'));
    for (var i = 0; i < 100 && page.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(page, findsOneWidget);
    final art = (await tester.runAsync(() => ArtworkRepository(db).watchForChild(1).first))!.single;
    expect(art.style, 'paper');
    final loaded = (await tester.runAsync(() => service.load(art.id)))!;
    final sheet = loaded.document.ops.single as PictureOp;
    expect(sheet.picture, ColoringDocument.paperPicture);
    expect(loaded.document.canUndo, isFalse, reason: 'the drawing is the page');
    // Taller than wide, like the cow; the long side as long as a blank sheet's.
    expect(loaded.document.height, ArtworkService.blankHeight);
    expect(loaded.document.width, lessThan(loaded.document.height));
    // The bucket colors the paper, as on a blank sheet.
    expect(find.bySemanticsLabel(Strings.paperColor), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });

  test('a photo with nothing drawn, or not a photo at all, gives nothing', () {
    final blank = img.Image(width: 400, height: 300)..clear(img.ColorRgb8(236, 232, 220));
    expect(paperDrawing(img.encodeJpg(blank)), isNull);
    expect(paperDrawing(File('test/assets/paper_drawing.jpg').readAsBytesSync().sublist(0, 100)), isNull);
  });
}
