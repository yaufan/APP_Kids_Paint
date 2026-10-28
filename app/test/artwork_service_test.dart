import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kids_paint/core/artwork_service.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/db/database.dart';
import 'package:kids_paint/core/festivals.dart';
import 'package:kids_paint/core/places.dart';
import 'package:kids_paint/core/repositories.dart';
import 'package:kids_paint/core/storage/artwork_store.dart';
import 'package:kids_paint/features/canvas/coloring.dart';

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

  test('a drawing on a photo is cut out where it was colored, with the lines around it', () {
    // A 40 x 40 page: a square outline 10..29, painted red inside; the
    // lines of the rest of the photo stay white and are left out.
    const w = 40, h = 40, white = 0xFFFFFFFF;
    final lines = Uint8List(w * h)..fillRange(0, w * h, 255);
    final rgba = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if ((x == 10 || x == 29) && y >= 10 && y <= 29 || (y == 10 || y == 29) && x >= 10 && x <= 29) lines[i] = 0;
        if (x == 36) lines[i] = 0; // a line far from the painting
        if (x > 10 && x < 29 && y > 10 && y < 29) rgba.setRange(i * 4, i * 4 + 3, [0xFF, 0x5E, 0x5B]);
      }
    }
    final sprite = img.decodePng(renderPaintedSprite(rgba, lines, white, w, h))!;
    expect((sprite.width, sprite.height), (20, 20), reason: 'the painting and its outline, not the far line');
    expect(sprite.getPixel(10, 10).r, 0xFF);
    expect(sprite.getPixel(0, 10).a, 255, reason: 'the outline');

    final nothing = img.decodePng(renderPaintedSprite(Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255), lines, white, w, h))!;
    expect((nothing.width, nothing.height), (1, 1), reason: 'nothing colored, nothing to cut out');

    // The background colored too (the area running off the page): left out,
    // the square stays. With only the background colored, that is kept.
    final labels = Uint16List(w * h)..fillRange(0, w * h, 1);
    for (var y = 11; y < 29; y++) {
      for (var x = 11; x < 29; x++) {
        labels[y * w + x] = 2;
      }
    }
    final both = Uint8List.fromList(rgba);
    for (var i = 0; i < w * h; i++) {
      if (labels[i] == 1 && lines[i] == 255) both.setRange(i * 4, i * 4 + 3, [0x5F, 0xCB, 0x79]);
    }
    final square = img.decodePng(renderPaintedSprite(both, lines, white, w, h, labels: labels))!;
    expect((square.width, square.height), (20, 20), reason: 'just the square and its outline');
    final sky = Uint8List.fromList(both);
    for (var i = 0; i < w * h; i++) {
      if (labels[i] == 2) sky.setRange(i * 4, i * 4 + 3, [255, 255, 255]);
    }
    final whole = img.decodePng(renderPaintedSprite(sky, lines, white, w, h, labels: labels))!;
    expect((whole.width, whole.height), (40, 40), reason: 'only the background colored: it is the picture');
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
    }, timeout: const Timeout(Duration(minutes: 3))); // 132 pages

    test('every creature has a picture in its colors to pick it by', () {
      for (final c in Creature.values) {
        final preview = img.decodePng(File('assets/previews/${c.name}.png').readAsBytesSync())!;
        expect(preview.width == 256 || preview.height == 256, isTrue, reason: '${c.name}: small, the same size');
        expect(preview.getPixel(0, 0).a, 0, reason: '${c.name}: cut out of the paper');
      }
    });

    test('quick saves land in order and leave a whole file', () async {
      final art = await service.saveBlank(childId: childId);
      final page = await service.load(art.id);
      final saves = <Future<void>>[];
      for (var i = 0; i < 12; i++) {
        page.document.fill(10, 10, 0xFF000000 | (i * 20) << 8);
        saves.add(service.saveOps(art, page.document)); // not awaited, like the canvas
      }
      await Future.wait(saves);
      final again = await service.load(art.id);
      expect(again.document.ops, hasLength(12));
      expect(again.document.colorAt(10, 10), page.document.colorAt(10, 10));
    });

    test('a sent postcard stays finished, even with every mark undone', () async {
      final art = await service.saveBlank(childId: childId);
      final page = await service.load(art.id);
      page.document.fill(10, 10, 0xFFFF5E5B);
      await service.send(page, await PlaceRepository(db).defaultPlace(childId, PlaceKind.park));
      final sent = await service.load(art.id);
      sent.document.undo();
      await service.saveFinished(sent);
      expect((await repo.get(art.id)).isCompleted, isTrue);
    });

    test('a drawing on paper leaves a cut-out when finished, and one is made for older ones', () async {
      final art = await service.saveBlank(childId: childId);
      final page = await service.load(art.id);
      page.document.add(CrayonOp(1, 0xFFFF5E5B, 12, [(x: 100, y: 100), (x: 300, y: 200)]));
      await service.send(page, await PlaceRepository(db).defaultPlace(childId, PlaceKind.park));
      final files = service.filesOf(art);
      final sprite = img.decodePng(files.sprite.readAsBytesSync())!;
      expect((sprite.width, sprite.height), (225, 125), reason: 'just the stroke: 200 by 100, and 12 more at each end');

      // A picture from before 0.17 had none: it is made from its files.
      files.sprite.deleteSync();
      expect(await service.ensureSprite(await repo.get(art.id)), isTrue);
      expect(img.decodePng(files.sprite.readAsBytesSync())!.width, 225);
    });

    test('a picture pressed onto another page is copied into it and comes back when it opens', () async {
      final dog = await service.saveBlank(childId: childId);
      final dogPage = await service.load(dog.id);
      dogPage.document.fill(10, 10, 0xFF4DA3FF); // the paper: all of it
      dogPage.document.add(CrayonOp(1, 0xFFFF5E5B, 20, [(x: 300, y: 400)]));
      await service.send(dogPage, await PlaceRepository(db).defaultPlace(childId, PlaceKind.home));

      final art = await service.saveBlank(childId: childId);
      final (name, picture) = await service.copyPicture(dog, art);
      expect(service.filesOf(art).picture(name).existsSync(), isTrue);
      final page = await service.load(art.id);
      page.document.pictures[name] = picture;
      page.document.add(PictureOp(name, 300, 400, 200));
      await service.saveOps(art, page.document);

      // The dog's own files go; the page keeps its copy.
      await service.delete(dog);
      final again = await service.load(art.id);
      expect(again.document.pictures.keys, [name]);
      expect(again.document.rgba, page.document.rgba);
      expect(again.document.colorAt(300, 400), isNot(0xFFFFFFFF));
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
