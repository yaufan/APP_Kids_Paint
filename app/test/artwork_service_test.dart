import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/festivals.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';

void main() {
  test('saved photos lose their EXIF (GPS, time taken) but stay upright', () {
    final photo = img.Image(width: 40, height: 20)..exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(25, 1);
    photo.exif.imageIfd.orientation = 6; // rotated 90 degrees
    final jpeg = img.encodeJpg(photo);
    expect(img.decodeJpgExif(jpeg)!.gpsIfd.isEmpty, isFalse);

    final clean = withoutMetadata(Uint8List.fromList(jpeg));
    final exif = img.decodeJpgExif(clean);
    expect(exif == null || (exif.gpsIfd.isEmpty && !exif.imageIfd.hasOrientation), isTrue);
    final upright = img.decodeJpg(clean)!;
    expect((upright.width, upright.height), (20, 40));
  });

  test('photos that cannot be decoded are kept', () {
    final junk = Uint8List.fromList([1, 2, 3]);
    expect(withoutMetadata(junk), junk);
  });

  test('a creature sprite keeps the creature and its outline, and drops the page around it', () {
    // A 40 x 40 page with a square outline from 10 to 29: inside is region 2.
    const w = 40, h = 40;
    final lines = Uint8List(w * h)..fillRange(0, w * h, 255);
    final labels = Uint16List(w * h)..fillRange(0, w * h, 1);
    for (var y = 10; y < 30; y++) {
      for (var x = 10; x < 30; x++) {
        final edge = x == 10 || x == 29 || y == 10 || y == 29;
        if (edge) lines[y * w + x] = 0;
        if (x > 10 && x < 29 && y > 10 && y < 29) labels[y * w + x] = 2;
      }
    }
    final rgba = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255);
    final sprite = img.decodePng(renderSprite(rgba, lines, labels, w, h))!;
    expect((sprite.width, sprite.height), (20, 20));
    expect(sprite.getPixel(10, 10).a, 255); // inside
    expect(sprite.getPixel(0, 10).a, 255); // the outline
    expect(sprite.getPixel(0, 10).r, 0);
  });

  group('pages not made from a photo', () {
    late AppDatabase db;
    late ArtworkService service;
    late ArtworkRepository repo;
    late int childId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = ArtworkRepository(db);
      service = ArtworkService(repo, ArtworkStore(Directory.systemTemp.createTempSync('kp_pages')));
      childId = (await ChildRepository(db).ensureDefault()).id;
    });
    tearDown(() => db.close());

    test('every creature page has areas to fill and leaves a sprite when finished', () async {
      for (final c in Creature.values) {
        final png = File('assets/pages/${c.name}.png').readAsBytesSync();
        final art = await service.saveTemplate(childId: childId, template: c.name, png: png);
        final page = await service.load(art.id);
        // The outside plus at least two areas (a whale is just body and belly).
        expect(page.document.regions.regionCount, greaterThan(2), reason: c.name);
        page.document.fill(300, 470, 0xFFFF5E5B);
        await service.saveFinished(page);
        final sprite = img.decodePng(service.filesOf(art).sprite.readAsBytesSync())!;
        expect(sprite.getPixel(0, 0).a, lessThan(255), reason: '${c.name}: the corner is see-through');
      }
    });

    test('blank paper is one big region', () async {
      final art = await service.saveBlank(childId: childId);
      expect(art.style, 'blank');
      final page = await service.load(art.id);
      expect(page.document.regions.regionCount, 1);
      expect(page.lines.every((v) => v == 255), isTrue);
    });

    test('every festival page has closed areas to fill, and marks its letter opened', () async {
      final since = DateTime.now().subtract(const Duration(minutes: 1));
      for (final f in Festival.values.where((f) => f.hasPage)) {
        final png = File('assets/pages/${f.name}.png').readAsBytesSync();
        final opened = repo.watchHasTemplate(childId, f.name, since);
        expect(await opened.first, isFalse);
        final art = await service.saveTemplate(childId: childId, template: f.name, png: png);
        expect((art.style, art.template), ('template', f.name));
        final page = await service.load(art.id);
        expect(page.document.regions.regionCount, greaterThan(8), reason: f.name);
        expect(await repo.watchHasTemplate(childId, f.name, since).first, isTrue);
      }
    });
  });
}
