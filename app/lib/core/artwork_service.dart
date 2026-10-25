import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../features/canvas/coloring.dart';
import '../features/lineart/line_art.dart';
import '../features/lineart/region_map.dart';
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
    final (w, h, lines) = (page.width, page.height, page.lines);
    await files.lines.writeAsBytes(await Isolate.run(() => encodeGrayPng(lines, w, h)));
    await files.regions.writeAsBytes(page.regions.encode());
    return _repo.create(childId: childId, style: style.name, detail: detail.name, folder: folder);
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
    await _repo.touch(page.artwork.id, completed: doc.ops.isNotEmpty);
  }

  /// Finishes the page and puts it on the map at [place].
  Future<void> send(LoadedPage page, Place place) async {
    await saveFinished(page);
    await _repo.send(page.artwork.id, place.id);
  }

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
