import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../features/canvas/coloring.dart';
import '../features/lineart/line_art.dart';
import '../features/lineart/region_map.dart';
import 'creatures.dart';
import 'db/database.dart';
import 'repositories.dart';
import 'storage/artwork_store.dart';

/// A page ready to color: its lines plus everything painted so far.
class LoadedPage {
  LoadedPage(this.artwork, this.lines, this.document);

  final Artwork artwork;

  /// Grayscale line pixels, 0 = ink, 255 = paper.
  final Uint8List lines;
  final ColoringDocument document;
}

/// Saving and loading artworks: database row plus files on disk.
class ArtworkService {
  ArtworkService(this._repo, this._store);

  final ArtworkRepository _repo;
  final ArtworkStore _store;

  static const thumbnailSize = 320;

  /// Size of a blank sheet of paper.
  static const blankWidth = 600, blankHeight = 800;

  /// A page made from a photo.
  Future<Artwork> saveNew({
    required int childId,
    required Uint8List photo,
    required LineArt page,
    required ArtStyle style,
    required DetailLevel detail,
  }) async {
    final folder = ArtworkStore.newFolderName();
    final files = await _store.create(folder);
    await files.photo.writeAsBytes(await Isolate.run(() => withoutMetadata(photo)));
    await _writePage(files, page);
    return _repo.create(childId: childId, style: style.name, detail: detail.name, folder: folder);
  }

  /// A page made from a built-in drawing ([png]: black lines on white),
  /// such as a festival page.
  Future<Artwork> saveTemplate({required int childId, required String template, required Uint8List png}) async {
    final page = await Isolate.run(() => lineArtFromPng(png));
    final folder = ArtworkStore.newFolderName();
    await _writePage(await _store.create(folder), page);
    return _repo.create(childId: childId, style: 'template', detail: DetailLevel.simple.name, folder: folder, template: template);
  }

  /// An empty sheet: no lines, one region, so the crayon goes anywhere.
  Future<Artwork> saveBlank({required int childId}) async {
    const n = blankWidth * blankHeight;
    final page = LineArt(
      width: blankWidth,
      height: blankHeight,
      lines: Uint8List(n)..fillRange(0, n, 255),
      regions: RegionMap(blankWidth, blankHeight, Uint16List(n)..fillRange(0, n, 1)),
    );
    final folder = ArtworkStore.newFolderName();
    await _writePage(await _store.create(folder), page);
    return _repo.create(childId: childId, style: 'blank', detail: DetailLevel.simple.name, folder: folder);
  }

  Future<void> _writePage(ArtworkFiles files, LineArt page) async {
    final (w, h, lines) = (page.width, page.height, page.lines);
    await files.lines.writeAsBytes(await Isolate.run(() => encodeGrayPng(lines, w, h)));
    await files.regions.writeAsBytes(page.regions.encode());
  }

  Future<LoadedPage> load(int artworkId) async {
    final artwork = await _repo.get(artworkId);
    final files = _store.open(artwork.folder);
    final png = await files.lines.readAsBytes();
    final lines = await Isolate.run(() => decodeGrayPng(png));
    final regions = RegionMap.decode(await files.regions.readAsBytes());
    final ops = await files.ops.exists()
        ? ColoringDocument.decodeOps(await files.ops.readAsString())
        : <PaintOp>[];
    return LoadedPage(artwork, lines, ColoringDocument(regions, ops));
  }

  /// Quick autosave after every change: just the list of operations.
  Future<void> saveOps(Artwork artwork, ColoringDocument doc) async {
    await _store.open(artwork.folder).ops.writeAsString(doc.encodeOps());
    await _repo.touch(artwork.id);
  }

  /// Full save when leaving the canvas: operations, finished picture, thumbnail.
  Future<void> saveFinished(LoadedPage page) async {
    final files = _store.open(page.artwork.folder);
    final doc = page.document;
    await files.ops.writeAsString(doc.encodeOps());
    final (w, h, rgba, lines) = (doc.width, doc.height, Uint8List.fromList(doc.rgba), page.lines);
    final (colored, thumb) = await Isolate.run(() => renderColored(rgba, lines, w, h));
    await files.colored.writeAsBytes(colored);
    await files.thumbnail.writeAsBytes(thumb);
    if (Creature.byName(page.artwork.template) != null) {
      final labels = doc.regions.labels;
      await files.sprite.writeAsBytes(await Isolate.run(() => renderSprite(rgba, lines, labels, w, h)));
    }
    await _repo.touch(page.artwork.id, completed: doc.ops.isNotEmpty);
  }

  /// Finishes the page and puts it on the map at [place].
  Future<void> send(LoadedPage page, Place place) async {
    await saveFinished(page);
    await _repo.send(page.artwork.id, place.id);
  }

  ArtworkFiles filesOf(Artwork artwork) => _store.open(artwork.folder);

  Future<void> delete(Artwork artwork) async {
    await _store.delete(artwork.folder);
    await _repo.delete(artwork.id);
  }
}

/// The photo re-encoded without EXIF (GPS, time taken, phone model), turned
/// upright first so dropping the orientation tag changes nothing. Photos
/// that cannot be decoded are kept as they are.
Uint8List withoutMetadata(Uint8List photo) {
  final image = img.decodeImage(photo);
  if (image == null) return photo;
  final upright = img.bakeOrientation(image)..exif = img.ExifData();
  return img.encodeJpg(upright, quality: 90);
}

/// A coloring page from a PNG drawing: its gray lines and fill regions.
LineArt lineArtFromPng(Uint8List png) {
  final image = img.decodePng(png)!;
  final lines = decodeGrayPng(png);
  return LineArt(
    width: image.width,
    height: image.height,
    lines: lines,
    regions: RegionMap.fromLines(lines, image.width, image.height),
  );
}

Uint8List encodeGrayPng(Uint8List gray, int width, int height) {
  final image = img.Image.fromBytes(
      width: width, height: height, bytes: Uint8List.fromList(gray).buffer, numChannels: 1);
  return img.encodePng(image);
}

Uint8List decodeGrayPng(Uint8List png) {
  final image = img.decodePng(png)!;
  final out = Uint8List(image.width * image.height);
  var i = 0;
  for (final p in image) {
    out[i++] = p.r.toInt();
  }
  return out;
}

/// Multiplies the color layer by the lines; returns (full PNG, thumbnail PNG).
(Uint8List, Uint8List) renderColored(Uint8List rgba, Uint8List lines, int width, int height) {
  final out = Uint8List(rgba.length);
  for (var i = 0; i < lines.length; i++) {
    final l = lines[i];
    out[i * 4] = rgba[i * 4] * l ~/ 255;
    out[i * 4 + 1] = rgba[i * 4 + 1] * l ~/ 255;
    out[i * 4 + 2] = rgba[i * 4 + 2] * l ~/ 255;
    out[i * 4 + 3] = 255;
  }
  final image = img.Image.fromBytes(width: width, height: height, bytes: out.buffer, numChannels: 4);
  final scale = ArtworkService.thumbnailSize / math.max(width, height);
  final thumb = img.copyResize(image,
      width: (width * scale).round(), height: (height * scale).round(), interpolation: img.Interpolation.average);
  return (img.encodePng(image), img.encodePng(thumb));
}

/// A colored creature cut out of its page, cropped, at most [maxSide] px.
///
/// Everything in the page's outside region (the one at the corner) is see-
/// through except the ink, which keeps its softness, so the outline stays
/// whole and smooth.
Uint8List renderSprite(Uint8List rgba, Uint8List lines, Uint16List labels, int width, int height, {int maxSide = 360}) {
  final outside = labels[0];
  final out = Uint8List(width * height * 4);
  var x0 = width, y0 = height, x1 = -1, y1 = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = y * width + x;
      final l = lines[i];
      final alpha = labels[i] == outside ? 255 - l : 255;
      if (alpha < 8) continue;
      final o = i * 4;
      out[o] = rgba[o] * l ~/ 255;
      out[o + 1] = rgba[o + 1] * l ~/ 255;
      out[o + 2] = rgba[o + 2] * l ~/ 255;
      out[o + 3] = alpha;
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
      if (y < y0) y0 = y;
      if (y > y1) y1 = y;
    }
  }
  final image = img.Image.fromBytes(width: width, height: height, bytes: out.buffer, numChannels: 4);
  if (x1 < x0) return img.encodePng(img.Image(width: 1, height: 1, numChannels: 4));
  var sprite = img.copyCrop(image, x: x0, y: y0, width: x1 - x0 + 1, height: y1 - y0 + 1);
  final scale = maxSide / math.max(sprite.width, sprite.height);
  if (scale < 1) {
    sprite = img.copyResize(sprite,
        width: (sprite.width * scale).round(), height: (sprite.height * scale).round(), interpolation: img.Interpolation.average);
  }
  return img.encodePng(sprite);
}
