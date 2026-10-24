import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'line_art.dart';
import 'region_map.dart';

/// Placeholder engine in pure Dart: blur, Sobel edges, thick lines.
///
/// Good enough to exercise the whole app flow on any device. It will be
/// replaced by the DexiNed-based engine validated in `prototypes/lineart`.
class SimpleLineArtEngine implements LineArtEngine {
  const SimpleLineArtEngine({this.size = 1024});

  /// Long side of the produced page, in pixels.
  final int size;

  @override
  Future<LineArt> convert(Uint8List photo, ArtStyle style, DetailLevel detail) =>
      Isolate.run(() => convertSync(photo, style, detail, size: size));

  static LineArt convertSync(Uint8List photo, ArtStyle style, DetailLevel detail,
      {int size = 1024}) {
    final decoded = img.decodeImage(photo);
    if (decoded == null) throw const FormatException('unsupported image');
    var image = img.bakeOrientation(decoded);
    final scale = size / math.max(image.width, image.height);
    image = img.copyResize(image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.average);

    final p = _Params.of(style, detail, size);
    final gray = img.grayscale(img.gaussianBlur(image, radius: p.blur));
    final edges = img.sobel(gray);

    final w = image.width, h = image.height, n = w * h;
    final strong = Uint8List(n);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (edges.getPixel(x, y).r > p.threshold) strong[y * w + x] = 1;
      }
    }
    _dropSpecks(strong, w, h, p.minStroke);
    final lines = _thicken(strong, w, h, p.lineRadius);
    final regions = RegionMap.fromLines(lines, w, h, gap: p.gap, minRegion: p.minRegion);
    return LineArt(width: w, height: h, lines: lines, regions: regions);
  }

  /// Removes edge fragments smaller than [minPixels] (texture, noise).
  static void _dropSpecks(Uint8List mask, int w, int h, int minPixels) {
    final seen = Uint8List(mask.length);
    final stack = <int>[];
    for (var start = 0; start < mask.length; start++) {
      if (mask[start] == 0 || seen[start] == 1) continue;
      final members = <int>[];
      seen[start] = 1;
      stack.add(start);
      while (stack.isNotEmpty) {
        final i = stack.removeLast();
        members.add(i);
        final x = i % w, y = i ~/ w;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
            final j = ny * w + nx;
            if (mask[j] == 1 && seen[j] == 0) {
              seen[j] = 1;
              stack.add(j);
            }
          }
        }
      }
      if (members.length < minPixels) {
        for (final i in members) {
          mask[i] = 0;
        }
      }
    }
  }

  /// Draws every edge pixel as a round dot: even, thick coloring-book lines.
  static Uint8List _thicken(Uint8List mask, int w, int h, int r) {
    final page = Uint8List(mask.length)..fillRange(0, mask.length, 255);
    final r2 = r * r;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (mask[y * w + x] == 0) continue;
        for (var dy = -r; dy <= r; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= h) continue;
          for (var dx = -r; dx <= r; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= w || dx * dx + dy * dy > r2) continue;
            page[ny * w + nx] = 0;
          }
        }
      }
    }
    return page;
  }
}

class _Params {
  const _Params(this.blur, this.threshold, this.minStroke, this.lineRadius, this.gap, this.minRegion);

  final int blur;
  final int threshold;
  final int minStroke;
  final int lineRadius;
  final int gap;
  final int minRegion;

  /// Cute pages keep fewer, thicker lines; simpler pages keep fewer lines.
  factory _Params.of(ArtStyle style, DetailLevel detail, int size) {
    final k = size / 1024;
    final base = switch (detail) {
      DetailLevel.simple => const _Params(4, 90, 120, 4, 8, 3000),
      DetailLevel.normal => const _Params(3, 70, 60, 3, 6, 1200),
      DetailLevel.detailed => const _Params(2, 55, 30, 2, 4, 500),
    };
    final p = style == ArtStyle.cute
        ? _Params(base.blur + 2, base.threshold + 20, base.minStroke * 2, base.lineRadius + 2,
            base.gap + 2, base.minRegion * 2)
        : base;
    int s(int v) => math.max(1, (v * k).round());
    return _Params(s(p.blur), p.threshold, s(p.minStroke), s(p.lineRadius), s(p.gap),
        math.max(1, (p.minRegion * k * k).round()));
  }
}
