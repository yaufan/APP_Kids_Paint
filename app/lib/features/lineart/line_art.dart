import 'dart:typed_data';

import 'region_map.dart';

enum ArtStyle { realistic, cute }

enum DetailLevel { simple, normal, detailed }

/// A coloring page: grayscale lines (0 = ink, 255 = paper) and its regions.
class LineArt {
  LineArt({required this.width, required this.height, required this.lines, required this.regions})
      : assert(lines.length == width * height);

  final int width;
  final int height;
  final Uint8List lines;
  final RegionMap regions;
}

/// Turns a photo into a coloring page.
///
/// The app only talks to this interface so engines can be swapped: the
/// simple built-in one today, the DexiNed port from `prototypes/lineart`
/// next, and the server-side Q-version (cute v2) later.
abstract interface class LineArtEngine {
  Future<LineArt> convert(Uint8List photo, ArtStyle style, DetailLevel detail);
}
