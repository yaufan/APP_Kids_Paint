import 'dart:convert';
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
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/printing.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:pdf/pdf.dart';

/// Keeps what would have gone to the print dialog.
class RecordingPrinter implements PagePrinter {
  final printed = <(List<Uint8List>, String)>[];

  @override
  Future<void> printPages(List<Uint8List> pages, {required String name}) async => printed.add((pages, name));
}

/// Printing coloring pages on paper (0.18).
void main() {
  Uint8List page(int w, int h) => img.encodePng(img.Image(width: w, height: h, numChannels: 1)..clear(img.ColorUint8.rgb(255, 255, 255)));

  test('one page a sheet, upright or turned to fit', () async {
    final pdf = await coloringPdf([page(600, 800), page(800, 600)], PdfPageFormat.a4);
    final text = latin1.decode(pdf);
    expect(text.startsWith('%PDF-'), isTrue);
    expect(RegExp(r'/Type\s*/Page\b').allMatches(text), hasLength(2));
    // A4 is 595 x 842 points: the second sheet is turned.
    expect(text, contains(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+595\.\d*\s+841\.\d*\s*\]')));
    expect(text, contains(RegExp(r'/MediaBox\s*\[\s*0\s+0\s+841\.\d*\s+595\.\d*\s*\]')));
  });

  testWidgets("parents pick pages, the app's and the family's own, and print them", (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = ArtworkStore(Directory.systemTemp.createTempSync('kp_print'));
    final printer = RecordingPrinter();
    // A page made from a photo, with its lines on disk.
    final own = (await tester.runAsync(() async {
      final childId = (await ChildRepository(db).ensureDefault()).id;
      final files = await store.create('photo-page');
      await files.lines.writeAsBytes(page(300, 400));
      return ArtworkRepository(db).create(childId: childId, style: 'cute', detail: 'simple', folder: 'photo-page');
    }))!;
    await tester.runAsync(() => SettingsRepository(db).setWelcomed());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(store),
        systemSoundsProvider.overrideWithValue(const SilentSounds()),
        printerProvider.overrideWithValue(printer),
      ],
      child: const KidsPaintApp(),
    ));
    await tester.pump();
    GoRouter.of(tester.element(find.byType(Scaffold).first)).push('/parent/print');
    final mine = find.byKey(ValueKey('print-own-${own.id}'));
    for (var i = 0; i < 40 && mine.evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(mine);
    await tester.tap(find.byKey(const ValueKey('print-lunarNewYear')));
    await tester.scrollUntilVisible(find.byKey(ValueKey('print-${Creature.cow.name}')), 300);
    await tester.tap(find.byKey(ValueKey('print-${Creature.cow.name}')));
    await tester.pump();
    expect(find.text(Strings.printNow(3)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('print-now')));
    for (var i = 0; i < 40 && printer.printed.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    final (pages, name) = printer.printed.single;
    expect(name, Strings.printName);
    expect(pages.map((p) => img.decodePng(p)!.width), [300, 600, 600], reason: 'in the order picked');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
