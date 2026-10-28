import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/album_export.dart';
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';

class _Album implements PhotoAlbum {
  _Album({this.allowed = true});

  final bool allowed;
  final saved = <String>[];

  @override
  Future<bool> allow() async => allowed;

  @override
  Future<void> add(File picture) async => saved.add(picture.path);
}

void main() {
  late AppDatabase db;
  late ArtworkStore store;
  late ArtworkService service;
  late int childId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    store = ArtworkStore(Directory.systemTemp.createTempSync('kp_album'));
    service = ArtworkService(ArtworkRepository(db), store);
    childId = (await ChildRepository(db).ensureDefault()).id;
  });
  tearDown(() => db.close());

  Future<void> finish() async {
    final art = await service.saveBlank(childId: childId);
    final page = await service.load(art.id);
    page.document.fill(10, 10, 0xFFFF5E5B);
    await service.saveFinished(page);
  }

  AlbumExport export(PhotoAlbum album) => AlbumExport(ArtworkRepository(db), SettingsRepository(db), store, album);

  test('finished pictures go to the album once; next time only the new ones', () async {
    await finish();
    await finish();
    await service.saveBlank(childId: childId); // started, not finished: stays
    final album = _Album();
    expect(await export(album).waiting(), 2);
    expect(await export(album).saveNew(), 2);
    expect(album.saved.every((p) => p.endsWith('colored.png')), isTrue);
    expect(await export(album).waiting(), 0);

    await finish();
    expect(await export(album).saveNew(), 1);
    expect(album.saved, hasLength(3));
  });

  test('a picture started before others and finished after they were saved still goes', () async {
    final early = await service.saveBlank(childId: childId); // left unfinished for now
    await finish();
    final album = _Album();
    expect(await export(album).saveNew(), 1);
    final page = await service.load(early.id);
    page.document.fill(10, 10, 0xFF4DA3FF);
    await service.saveFinished(page);
    expect(await export(album).waiting(), 1);
    expect(await export(album).saveNew(), 1);
    expect(album.saved, hasLength(2));
  });

  test('nothing is saved, or marked saved, without permission', () async {
    await finish();
    expect(await export(_Album(allowed: false)).saveNew(), isNull);
    expect(await export(_Album()).waiting(), 1);
  });
}
