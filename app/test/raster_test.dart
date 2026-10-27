import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/features/lineart/raster.dart' as raster;

void main() {
  const w = 60, h = 60;

  void box(Uint8List m, int x0, int y0, int x1, int y1) {
    for (var x = x0; x <= x1; x++) {
      m[y0 * w + x] = 1;
      m[y1 * w + x] = 1;
    }
    for (var y = y0; y <= y1; y++) {
      m[y * w + x0] = 1;
      m[y * w + x1] = 1;
    }
  }

  test('lines around areas too small to color go; lines between big areas and clear little shapes stay', () {
    final center = Uint8List(w * h);
    box(center, 5, 5, 54, 54); // the outline
    for (var y = 5; y <= 54; y++) {
      center[y * w + 30] = 1; // splits it into two halves big enough to color
    }
    box(center, 12, 12, 15, 15); // a faint fleck inside the left half
    box(center, 40, 12, 43, 15); // an eye, drawn clearly, in the right half
    final edges = Float32List(w * h);
    for (var i = 0; i < edges.length; i++) {
      edges[i] = i % w >= 40 && i % w <= 43 && i ~/ w >= 12 && i ~/ w <= 15 ? 0.9 : 0.5;
    }
    raster.removeTinyAreas(center, edges, w, h, 50, keep: 0.75);
    expect(center[12 * w + 13], 0, reason: 'the fleck is gone');
    expect(center[12 * w + 41], 1, reason: 'the eye stays');
    expect(center[5 * w + 20], 1, reason: 'the outline stays');
    expect(center[40 * w + 30], 1, reason: 'the line between the halves stays');
  });

  test('skin is found by its color', () {
    final rgb = Uint8List.fromList([224, 172, 138, 60, 120, 220, 250, 250, 250, 20, 20, 20]);
    expect(raster.skin(rgb, 4, 1), [1, 0, 0, 0]);
  });
}
