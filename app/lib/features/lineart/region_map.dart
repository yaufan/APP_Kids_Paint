import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Which fill region every pixel of a coloring page belongs to.
///
/// Label 0 never appears once a map is built: every pixel, including the
/// line pixels, belongs to some region, so color can sit under the lines.
class RegionMap {
  RegionMap(this.width, this.height, this.labels)
      : assert(labels.length == width * height);

  final int width;
  final int height;
  final Uint16List labels;

  int get regionCount => labels.isEmpty ? 0 : labels.reduce(math.max);

  int labelAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return 0;
    return labels[y * width + x];
  }

  /// Builds regions from a grayscale page (0 = ink, 255 = paper).
  ///
  /// Lines are thickened by [gap] pixels so that small breaks in a line do
  /// not join two areas; the areas left over become seeds, and each seed then
  /// grows back over the thickened band and the lines themselves. A gap in a
  /// line therefore becomes an invisible border instead of a leak. Areas
  /// smaller than [minRegion] pixels are absorbed by their neighbors.
  static RegionMap fromLines(
    Uint8List page,
    int width,
    int height, {
    int gap = 6,
    int minRegion = 200,
  }) {
    final n = width * height;
    final ink = Uint8List(n);
    for (var i = 0; i < n; i++) {
      if (page[i] < 128) ink[i] = 1;
    }
    final blocked = _dilate(ink, width, height, gap);

    // Seeds: connected areas of paper that survive the thickened lines.
    // Every pixel is visited once; a seed's pixels sit together in [order]
    // so a seed that is too small can be undone.
    final labels = Uint16List(n);
    final order = Int32List(n);
    final tried = Uint8List(n); // pixels of seeds that were too small
    var end = 0, next = 0;
    for (var start = 0; start < n; start++) {
      if (blocked[start] == 1 || labels[start] != 0 || tried[start] == 1) continue;
      final label = ++next;
      final first = end;
      labels[start] = label;
      order[end++] = start;
      for (var k = first; k < end; k++) {
        final i = order[k];
        final x = i % width;
        if (x > 0 && blocked[i - 1] == 0 && labels[i - 1] == 0) {
          labels[i - 1] = label;
          order[end++] = i - 1;
        }
        if (x < width - 1 && blocked[i + 1] == 0 && labels[i + 1] == 0) {
          labels[i + 1] = label;
          order[end++] = i + 1;
        }
        if (i >= width && blocked[i - width] == 0 && labels[i - width] == 0) {
          labels[i - width] = label;
          order[end++] = i - width;
        }
        if (i < n - width && blocked[i + width] == 0 && labels[i + width] == 0) {
          labels[i + width] = label;
          order[end++] = i + width;
        }
      }
      if (end - first < minRegion) {
        for (var k = first; k < end; k++) {
          labels[order[k]] = 0;
          tried[order[k]] = 1;
        }
        end = first;
        next--;
      }
      if (next >= 65534) break; // Uint16 labels; real pages have far fewer.
    }

    // Grow every seed outward at the same speed until all pixels are taken:
    // a breadth-first queue that starts with every seed pixel.
    if (end == 0) {
      labels.fillRange(0, n, 1); // a page with no paper: one region
      return RegionMap(width, height, labels);
    }
    for (var head = 0; head < end; head++) {
      final i = order[head];
      final label = labels[i];
      final x = i % width;
      if (x > 0 && labels[i - 1] == 0) {
        labels[i - 1] = label;
        order[end++] = i - 1;
      }
      if (x < width - 1 && labels[i + 1] == 0) {
        labels[i + 1] = label;
        order[end++] = i + 1;
      }
      if (i >= width && labels[i - width] == 0) {
        labels[i - width] = label;
        order[end++] = i - width;
      }
      if (i < n - width && labels[i + width] == 0) {
        labels[i + width] = label;
        order[end++] = i + width;
      }
    }
    return RegionMap(width, height, labels);
  }

  /// Square dilation of a 0/1 mask by [r] pixels, in O(n) per axis.
  static Uint8List _dilate(Uint8List mask, int width, int height, int r) {
    if (r <= 0) return Uint8List.fromList(mask);
    final rows = Uint8List(mask.length);
    final prefix = Int32List(math.max(width, height) + 1);
    for (var y = 0; y < height; y++) {
      final row = y * width;
      for (var x = 0; x < width; x++) {
        prefix[x + 1] = prefix[x] + mask[row + x];
      }
      for (var x = 0; x < width; x++) {
        final a = math.max(0, x - r), b = math.min(width, x + r + 1);
        if (prefix[b] - prefix[a] > 0) rows[row + x] = 1;
      }
    }
    final out = Uint8List(mask.length);
    for (var x = 0; x < width; x++) {
      for (var y = 0; y < height; y++) {
        prefix[y + 1] = prefix[y] + rows[y * width + x];
      }
      for (var y = 0; y < height; y++) {
        final a = math.max(0, y - r), b = math.min(height, y + r + 1);
        if (prefix[b] - prefix[a] > 0) out[y * width + x] = 1;
      }
    }
    return out;
  }

  /// Compact file form: magic, width, height, then gzip of the labels.
  Uint8List encode() {
    final header = ByteData(12)
      ..setUint32(0, _magic)
      ..setUint32(4, width)
      ..setUint32(8, height);
    final body = gzip.encode(labels.buffer.asUint8List(
        labels.offsetInBytes, labels.lengthInBytes));
    return Uint8List.fromList([...header.buffer.asUint8List(), ...body]);
  }

  static RegionMap decode(Uint8List bytes) {
    final header = ByteData.sublistView(bytes, 0, 12);
    if (header.getUint32(0) != _magic) {
      throw const FormatException('not a region map');
    }
    final width = header.getUint32(4), height = header.getUint32(8);
    final raw = Uint8List.fromList(gzip.decode(bytes.sublist(12)));
    return RegionMap(width, height, raw.buffer.asUint16List(0, width * height));
  }

  static const _magic = 0x4B505231; // "KPR1"
}
