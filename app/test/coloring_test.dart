import 'dart:typed_data';

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

  test('blank paper: the bucket colors the paper behind the drawing, and undo brings it back', () {
    final blank = RegionMap(20, 20, Uint16List(400)..fillRange(0, 400, 1));
    final doc = ColoringDocument(blank)..add(CrayonOp(1, red, 2, [(x: 5, y: 5), (x: 15, y: 5)]));
    doc.add(const PaperOp(blue));
    expect(doc.colorAt(10, 5), red, reason: 'the crayon stays on top');
    expect(doc.colorAt(10, 15), blue);
    final reloaded = ColoringDocument(blank, ColoringDocument.decodeOps(doc.encodeOps()));
    expect(reloaded.rgba, doc.rgba);
    doc.undo();
    expect(doc.colorAt(10, 15), white);
  });

  group('pictures as stamps (0.17)', () {
    // A 4 x 2 picture: left half red, right half see-through.
    final picture = StampPicture(4, 2, Uint8List.fromList([
      for (var i = 0; i < 8; i++) ...(i % 4 < 2 ? [0xE5, 0x39, 0x35, 255] : [0, 0, 0, 0]),
    ]));

    test('a picture goes onto the page where it is drawn, over any region, see-through where it is', () {
      final doc = ColoringDocument(regions, [], {'dog': picture})..fill(32, 32, blue);
      // 16 px across, centered on the square's left border at (12, 32).
      doc.add(const PictureOp('dog', 12, 32, 16));
      expect(doc.colorAt(6, 32), red, reason: 'its left half, outside the square');
      expect(doc.colorAt(11, 32), red, reason: 'and over the border');
      expect(doc.colorAt(18, 32), blue, reason: 'its see-through half shows the page');
    });

    test('a picture stamp survives a save and reload, and undo takes it off', () {
      final doc = ColoringDocument(regions, [], {'dog': picture})..add(const PictureOp('dog', 32, 32, 20));
      final ops = ColoringDocument.decodeOps(doc.encodeOps());
      expect(ColoringDocument.picturesIn(ops), {'dog'});
      expect(ColoringDocument(regions, ops, {'dog': picture}).rgba, doc.rgba);
      doc.undo();
      expect(doc.colorAt(28, 32), white);
    });

    test('a page whose picture is gone still opens, without it', () {
      final doc = ColoringDocument(regions, [const PictureOp('gone', 32, 32, 20)]);
      expect(doc.colorAt(28, 32), white);
    });
  });

  group('the time-lapse (0.17)', () {
    List<PaintOp> busyPage() {
      final inside = regions.labelAt(32, 32);
      return [
        FillOp(regions.labelAt(2, 2), blue),
        CrayonOp(inside, red, 3, [for (var x = 22; x < 42; x += 2) (x: x.toDouble(), y: 32.0)], brush: Brush.watercolor),
        StampOp(inside, red, StampShape.heart, 32, 26, 5),
        CrayonOp(inside, blue, 2, [(x: 24.0, y: 38.0), (x: 40.0, y: 38.0)], brush: Brush.neon),
      ];
    }

    test('played to the end it looks exactly like the page', () {
      final page = ColoringDocument(regions, busyPage());
      final replay = Replay(page.ops, ColoringDocument(regions));
      for (var step = 0; !replay.finished; step += 3) {
        replay.playTo(step);
      }
      expect(replay.target.rgba, page.rgba);
      expect(replay.progress, 1);
    });

    test('strokes come point by point, the rest a step each', () {
      final ops = busyPage();
      final replay = Replay(ops, ColoringDocument(regions));
      expect(replay.total, Replay.opUnits + 10 + Replay.opUnits + 2);
      expect(replay.playTo(Replay.opUnits), [ops[0]], reason: 'the fill first');
      expect(replay.target.colorAt(2, 2), blue);
      expect(replay.target.colorAt(40, 32), white, reason: 'the stroke has not got there yet');
      expect(replay.playTo(Replay.opUnits + 3), [ops[1]]);
      expect(replay.target.colorAt(22, 32), isNot(white), reason: 'it has begun');
      expect(replay.target.colorAt(40, 32), white);
    });
  });

  test('three sets of twelve colors, all different, each with a name', () {
    expect(kidPaletteSets, hasLength(3));
    expect(kidPaletteSets.first.colors, kidPalette);
    final all = [for (final s in kidPaletteSets) ...s.colors];
    expect(all.toSet(), hasLength(36));
    for (final s in kidPaletteSets) {
      expect((s.colors.length, s.names.length), (12, 12), reason: s.name);
      expect(s.names.toSet(), hasLength(12), reason: s.name);
    }
  });

  group('more tools', () {
    late RegionMap blank;
    setUp(() => blank = RegionMap(60, 60, Uint16List(3600)..fillRange(0, 3600, 1)));

    test('the rainbow brush changes color along the stroke', () {
      final doc = ColoringDocument(blank)..add(CrayonOp(1, red, 3, [(x: 2, y: 30), (x: 58, y: 30)], brush: Brush.rainbow));
      final colors = {for (var x = 2; x < 58; x += 4) doc.colorAt(x, 30)};
      expect(colors.length, greaterThan(4));
      expect(colors, isNot(contains(white)));
    });

    test('glitter is the color with sparkles in fixed places', () {
      final doc = ColoringDocument(blank)..add(CrayonOp(1, blue, 20, [(x: 30, y: 30)], brush: Brush.glitter));
      final inside = [for (var y = 15; y < 45; y++) for (var x = 15; x < 45; x++) if ((x - 30) * (x - 30) + (y - 30) * (y - 30) < 200) doc.colorAt(x, y)];
      expect(inside.where((c) => c == blue).length, greaterThan(inside.length ~/ 2));
      expect(inside.where((c) => c != blue), isNotEmpty);
      final again = ColoringDocument(blank, ColoringDocument.decodeOps(doc.encodeOps()));
      expect(again.rgba, doc.rgba);
    });

    test('the eraser brings back the paper, even the color of blank paper', () {
      final doc = ColoringDocument(blank)
        ..add(const PaperOp(blue))
        ..add(CrayonOp(1, red, 4, [(x: 10, y: 10), (x: 50, y: 10)]))
        ..add(CrayonOp(1, red, 6, [(x: 30, y: 10)], brush: Brush.eraser));
      expect(doc.colorAt(30, 10), blue);
      expect(doc.colorAt(12, 10), red);
    });

    int channel(int color, int shift) => (color >> shift) & 0xFF;

    test('the dots pen leaves dots with paper between them', () {
      final doc = ColoringDocument(blank)..add(CrayonOp(1, red, 3, [(x: 4, y: 30), (x: 56, y: 30)], brush: Brush.dots));
      final along = [for (var x = 4; x < 56; x++) doc.colorAt(x, 30)];
      expect(along.where((c) => c == red).length, greaterThan(10));
      expect(along.where((c) => c == white).length, greaterThan(10));
    });

    test('the spray leaves specks, more of them in the middle', () {
      final doc = ColoringDocument(blank)..add(CrayonOp(1, red, 12, [(x: 10, y: 30), (x: 50, y: 30)], brush: Brush.spray));
      int specks(int y) => [for (var x = 12; x < 48; x++) doc.colorAt(x, y)].where((c) => c == red).length;
      expect(specks(30), greaterThan(0));
      expect(specks(30), lessThan(36), reason: 'not solid');
      expect(specks(30), greaterThan(specks(40)));
    });

    test('watercolor is see-through: pale on white, and blue over yellow turns green', () {
      const yellow = 0xFFFFD166;
      final doc = ColoringDocument(blank)
        ..add(CrayonOp(1, yellow, 6, [(x: 10, y: 20), (x: 50, y: 20)]))
        ..add(CrayonOp(1, blue, 6, [(x: 30, y: 10), (x: 30, y: 50)], brush: Brush.watercolor));
      final pale = doc.colorAt(30, 45);
      expect(pale, isNot(white));
      expect(pale, isNot(blue));
      final green = doc.colorAt(30, 20);
      expect(channel(green, 8), greaterThan(channel(green, 16)), reason: 'more green than red');
      expect(channel(green, 8), greaterThan(channel(green, 0)), reason: 'more green than blue');
      // Going back over the same place in one stroke does not darken it.
      final once = ColoringDocument(blank)..add(CrayonOp(1, blue, 6, [(x: 10, y: 30), (x: 50, y: 30)], brush: Brush.watercolor));
      final twice = ColoringDocument(blank)..add(CrayonOp(1, blue, 6, [(x: 10, y: 30), (x: 50, y: 30), (x: 10, y: 30)], brush: Brush.watercolor));
      expect(twice.colorAt(30, 30), once.colorAt(30, 30));
    });

    test('the neon pen is pale in the middle with the color around it', () {
      final doc = ColoringDocument(blank)..add(CrayonOp(1, blue, 10, [(x: 10, y: 30), (x: 50, y: 30)], brush: Brush.neon));
      expect(doc.colorAt(30, 30), isNot(blue));
      expect(channel(doc.colorAt(30, 30), 16), greaterThan(channel(blue, 16)), reason: 'paler');
      expect(doc.colorAt(30, 35), blue);
    });

    test('the stripes pen takes turns: the color, then a paler one', () {
      final doc = ColoringDocument(blank)..add(CrayonOp(1, red, 4, [(x: 4, y: 30), (x: 56, y: 30)], brush: Brush.stripes));
      final colors = {for (var x = 6; x < 54; x++) doc.colorAt(x, 30)};
      expect(colors.length, 2);
      expect(colors, contains(red));
    });

    test('a watercolor or neon stroke is still there after an undo redraws the page', () {
      for (final brush in [Brush.watercolor, Brush.neon]) {
        final doc = ColoringDocument(blank);
        final stroke = CrayonOp(1, blue, 6, [(x: 10, y: 30)], brush: brush);
        doc.add(stroke);
        stroke.points.add((x: 50, y: 30));
        doc.applyStroke(stroke, 1);
        final drawn = doc.colorAt(30, 30);
        expect(drawn, isNot(white), reason: '$brush');
        doc
          ..add(const PaperOp(0xFFFFD166))
          ..undo();
        expect(doc.colorAt(30, 30), drawn, reason: '$brush survives the redraw');
      }
    });

    test('every pen draws the same live, stroke by stroke, as when the page is opened again', () {
      for (final brush in Brush.values) {
        final live = ColoringDocument(blank)..add(const PaperOp(0xFFFFD166));
        final stroke = CrayonOp(1, blue, 7, [(x: 5, y: 8)], brush: brush);
        live.add(stroke);
        for (final p in [(x: 20.0, y: 12.0), (x: 31.5, y: 40.0), (x: 48.0, y: 22.0), (x: 55.0, y: 50.0), (x: 20.0, y: 52.0)]) {
          stroke.points.add(p);
          live.applyStroke(stroke, stroke.points.length - 1);
        }
        final opened = ColoringDocument(blank, ColoringDocument.decodeOps(live.encodeOps()));
        expect(opened.rgba, live.rgba, reason: '$brush');
      }
    });

    test('stamps keep their shape and stay in their region', () {
      final doc = ColoringDocument(regions)..add(StampOp(regions.labelAt(32, 32), red, StampShape.heart, 32, 32, 12));
      expect(doc.colorAt(32, 32), red);
      expect(doc.colorAt(32, 21), white, reason: 'the dip between the bumps');
      expect(doc.colorAt(2, 2), white);
      final again = ColoringDocument(regions, ColoringDocument.decodeOps(doc.encodeOps()));
      expect(again.rgba, doc.rgba);
    });

    test('every stamp shape covers its middle and not its corners', () {
      for (final shape in StampShape.values) {
        expect(stampContains(shape, 0, shape == StampShape.paw ? 0.35 : 0), isTrue, reason: '$shape');
        expect(stampContains(shape, 0.98, 0.98), isFalse, reason: '$shape');
      }
    });
  });
}
