import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/features/canvas/coloring.dart';
import 'package:kids_paint/features/lineart/region_map.dart';

import 'region_map_test.dart' show squarePage;

void main() {
  late RegionMap regions;
  const red = 0xFFE53935, blue = 0xFF1E88E5, white = 0xFFFFFFFF;

  setUp(() => regions = RegionMap.fromLines(squarePage(64), 64, 64, gap: 1, minRegion: 10));

  test('bucket fill colors only the tapped region', () {
    final doc = ColoringDocument(regions);
    expect(doc.fill(32, 32, red), isTrue);
    expect(doc.colorAt(32, 32), red);
    expect(doc.colorAt(2, 2), white);
  });

  test('undo restores the previous colors', () {
    final doc = ColoringDocument(regions)
      ..fill(32, 32, red)
      ..fill(32, 32, blue);
    expect(doc.colorAt(32, 32), blue);
    doc.undo();
    expect(doc.colorAt(32, 32), red);
    doc.undo();
    expect(doc.colorAt(32, 32), white);
    expect(doc.canUndo, isFalse);
  });

  test('the magic crayon never leaves the region it started in', () {
    final doc = ColoringDocument(regions);
    final inside = regions.labelAt(32, 32);
    // A stroke dragged from inside the square right across its border.
    doc.add(CrayonOp(inside, red, 4, [(x: 30, y: 32), (x: 63, y: 32)]));
    expect(doc.colorAt(30, 32), red);
    expect(doc.colorAt(60, 32), white);
  });

  test('operations survive a save and reload', () {
    final doc = ColoringDocument(regions)
      ..fill(2, 2, blue)
      ..add(CrayonOp(regions.labelAt(32, 32), red, 3, [(x: 30, y: 30), (x: 34, y: 34)]));
    final reloaded = ColoringDocument(regions, ColoringDocument.decodeOps(doc.encodeOps()));
    expect(reloaded.rgba, doc.rgba);
  });
}
