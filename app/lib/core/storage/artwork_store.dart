import 'dart:io';

import 'package:path/path.dart' as p;

/// Files that make up one artwork, all inside its own folder.
class ArtworkFiles {
  ArtworkFiles(this.dir);

  final Directory dir;

  /// The photo the page was made from.
  File get photo => File(p.join(dir.path, 'photo.jpg'));

  /// The coloring page: grayscale PNG, black lines on white.
  File get lines => File(p.join(dir.path, 'lines.png'));

  /// Fill regions for bucket fill and the stay-inside crayon.
  File get regions => File(p.join(dir.path, 'regions.bin'));

  /// Every paint operation, in order: undo, autosave and time-lapse replay.
  File get ops => File(p.join(dir.path, 'ops.json'));

  /// The colored result, rendered when the child leaves the canvas.
  File get colored => File(p.join(dir.path, 'colored.png'));

  /// Small preview for the gallery.
  File get thumbnail => File(p.join(dir.path, 'thumb.png'));

  /// The colored part cut out of the page: a creature roams its scene with
  /// it, other pictures hop about the town (0.17), and any can be a stamp.
  File get sprite => File(p.join(dir.path, 'sprite.png'));

  /// The copy of another picture's [sprite] pressed onto this page as a
  /// stamp, named after the folder it came from.
  File picture(String name) => File(p.join(dir.path, 'stamps', '$name.png'));
}

/// Keeps every artwork in the app's private documents folder.
class ArtworkStore {
  ArtworkStore(this.root);

  final Directory root;

  ArtworkFiles open(String folder) => ArtworkFiles(Directory(p.join(root.path, folder)));

  Future<ArtworkFiles> create(String folder) async {
    final files = open(folder);
    await files.dir.create(recursive: true);
    return files;
  }

  Future<void> delete(String folder) async {
    final dir = open(folder).dir;
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> deleteAll() async {
    if (await root.exists()) await root.delete(recursive: true);
  }

  /// A new, unique folder name such as `20261024-153012-482`.
  static String newFolderName([DateTime? now]) {
    final t = now ?? DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}-'
        '${t.millisecond.toString().padLeft(3, '0')}';
  }
}
