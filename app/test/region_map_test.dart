import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/features/lineart/region_map.dart';

/// A white page with a black square outline; [gapAt] leaves a hole in its
/// left side to check that bucket fill still cannot leak out.
Uint8List squarePage(int size, {int? gapAt, int gapSize = 3}) {
  final page = Uint8List(size * size)..fillRange(0, size * size, 255);
  final lo = size ~/ 4, hi = size * 3 ~/ 4;
  for (var i = lo; i <= hi; i++) {
    for (var t = 0; t < 2; t++) {
      page[(lo + t) * size + i] = 0; // top
      page[(hi - t) * size + i] = 0; // bottom
      page[i * size + hi - t] = 0; // right
      final inGap = gapAt != null && i >= gapAt && i < gapAt + gapSize;
      if (!inGap) page[i * size + lo + t] = 0; // left
    }
  }
  return page;
}

void main() {
  test('a closed outline splits the page into inside and outside', () {
    final map = RegionMap.fromLines(squarePage(64), 64, 64, gap: 1, minRegion: 10);
    expect(map.regionCount, 2);
    expect(map.labelAt(32, 32), isNot(map.labelAt(2, 2)));
  });

  test('a small gap in a line does not let the fill leak', () {
    final map = RegionMap.fromLines(squarePage(64, gapAt: 30), 64, 64, gap: 3, minRegion: 10);
    expect(map.regionCount, 2);
    expect(map.labelAt(32, 32), isNot(map.labelAt(2, 2)));
  });

  test('every pixel, including line pixels, belongs to a region', () {
    final map = RegionMap.fromLines(squarePage(64), 64, 64, gap: 2, minRegion: 10);
    expect(map.labels.every((l) => l > 0), isTrue);
  });

  test('tiny areas are absorbed by their neighbors', () {
    final page = squarePage(64);
    // A 2x2 hole of paper inside a solid ink blob.
    for (var y = 5; y < 11; y++) {
      for (var x = 5; x < 11; x++) {
        page[y * 64 + x] = (x >= 7 && x < 9 && y >= 7 && y < 9) ? 255 : 0;
      }
    }
    final map = RegionMap.fromLines(page, 64, 64, gap: 0, minRegion: 10);
    expect(map.regionCount, 2);
  });

  test('encode and decode round-trip', () {
    final map = RegionMap.fromLines(squarePage(40), 40, 40, gap: 1, minRegion: 5);
    final copy = RegionMap.decode(map.encode());
    expect(copy.width, 40);
    expect(copy.height, 40);
    expect(copy.labels, map.labels);
  });
}
