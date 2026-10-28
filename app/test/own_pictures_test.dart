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
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/providers.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/sharing.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/town/town_screen.dart';

/// Keeps what would have gone to the share sheet.
class RecordingSharer implements Sharer {
  final shared = <(Uint8List, String)>[];

  @override
  Future<void> shareImage(Uint8List png, {required String name, Rect? origin}) async => shared.add((png, name));
}

/// The child's own pictures (0.17): they live in the town, become stamps,
/// can be watched being colored again, and parents can share them.
void main() {
  late AppDatabase db;
  late ArtworkService service;
  late RecordingSharer sharer;

  Future<void> pumpApp(WidgetTester tester) async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final store = ArtworkStore(Directory.systemTemp.createTempSync('kp_own'));
    service = ArtworkService(ArtworkRepository(db), store);
    sharer = RecordingSharer();
    await tester.runAsync(() => SettingsRepository(db).setWelcomed());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        artworkStoreProvider.overrideWithValue(store),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 29, 10)),
        systemSoundsProvider.overrideWithValue(const SilentSounds()),
        sharerProvider.overrideWithValue(sharer),
      ],
      child: const KidsPaintApp(),
    ));
  }

  /// A drawing on paper, sent to [kind]: a red stroke across the middle.
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

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }

  GoRouter router(WidgetTester tester) => GoRouter.of(tester.element(find.byType(Scaffold).first));

  testWidgets('a picture sent to the park hops beside its pin and jumps when tapped', (tester) async {
    await pumpApp(tester);
    await sendDrawing(tester, PlaceKind.park);
    await settle(tester, find.bySemanticsLabel(Strings.townFolk(PlaceKind.park.label)));
    final before = tester.getRect(find.bySemanticsLabel(Strings.townFolk(PlaceKind.park.label)));
    await tester.tap(find.bySemanticsLabel(Strings.townFolk(PlaceKind.park.label)));
    await tester.pump(); // the jump starts
    await tester.pump(const Duration(milliseconds: 320));
    final up = tester.getRect(find.bySemanticsLabel(Strings.townFolk(PlaceKind.park.label)));
    expect(up.top, lessThan(before.top - 15), reason: 'it jumps');
    expect(find.byType(TownScreen), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('only the two newest pictures of a place live there', (tester) async {
    await pumpApp(tester);
    for (var i = 0; i < 3; i++) {
      await sendDrawing(tester, PlaceKind.home);
    }
    await settle(tester, find.bySemanticsLabel(Strings.townFolk(PlaceKind.home.label)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.bySemanticsLabel(Strings.townFolk(PlaceKind.home.label)), findsNWidgets(townFolksPerPlace));
    await unmount(tester);
  });

  testWidgets('a sent picture becomes a stamp to press onto a new page', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    final dog = await sendDrawing(tester, PlaceKind.home);
    final paper = (await tester.runAsync(() async => service.saveBlank(childId: dog.childId)))!;
    router(tester).push('/canvas/${paper.id}');
    await settle(tester, find.byKey(const ValueKey('page')));
    await tester.tap(find.bySemanticsLabel(Strings.stamp));
    await settle(tester, find.byKey(ValueKey('picture-stamp-${dog.id}')));
    await tester.ensureVisible(find.byKey(ValueKey('picture-stamp-${dog.id}')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('picture-stamp-${dog.id}')));
    await tester.pump();
    final page = tester.getRect(find.byKey(const ValueKey('page')));
    await tester.tapAt(page.center);
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    final ops = (await tester.runAsync(() async {
      // The autosave has written it; read it back from the page's files.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return (await service.load(paper.id)).document.ops;
    }))!;
    expect(ops.single, isA<PictureOp>().having((op) => op.picture, 'picture', dog.folder));
    expect(service.filesOf(paper).picture(dog.folder).existsSync(), isTrue);
    await unmount(tester);
  });

  testWidgets('the album plays a picture being colored again', (tester) async {
    await pumpApp(tester);
    final art = await sendDrawing(tester, PlaceKind.park);
    router(tester).push('/album');
    await settle(tester, find.byKey(ValueKey('replay-${art.id}')));
    await tester.tap(find.byKey(ValueKey('replay-${art.id}')));
    await settle(tester, find.byKey(const ValueKey('replay-page')));
    // A single stroke: the shortest replay, three seconds.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byKey(const ValueKey('replay-again')), findsNothing, reason: 'still playing');
    for (var i = 0; i < 30 && find.byKey(const ValueKey('replay-again')).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byKey(const ValueKey('replay-again')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('parents share a card made for it, about 1080 across, from parent mode', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    final art = await sendDrawing(tester, PlaceKind.park);
    router(tester).push('/parent/share');
    await settle(tester, find.byKey(ValueKey('share-pick-${art.id}')));
    await tester.tap(find.byKey(ValueKey('share-pick-${art.id}')));
    await settle(tester, find.text(Strings.sentTo(PlaceKind.park.label)));
    // Where it went can be left off.
    await tester.tap(find.text(Strings.sharedPlaceNone));
    await tester.pump();
    expect(find.text(Strings.sentTo(PlaceKind.park.label)), findsNothing);
    await tester.ensureVisible(find.text(Strings.shareNow));
    await tester.tap(find.text(Strings.shareNow));
    for (var i = 0; i < 40 && sharer.shared.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(sharer.shared, hasLength(1));
    final (png, name) = sharer.shared.single;
    expect(name, endsWith('.png'));
    final card = img.decodePng(png)!;
    expect(card.width, closeTo(1080, 2));
    expect(card.height / card.width, closeTo(5 / 4, 0.01));
    await unmount(tester);
  });
}
