import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kids_paint/features/lineart/line_art.dart';
import 'package:kids_paint/features/lineart/teed_engine.dart';

void main() {
  final weights = File('assets/models/teed.bin').readAsBytesSync();
  // A red disc on a light background: one subject, easy to outline.
  final photo = img.encodePng(
    img.fillCircle(img.Image(width: 400, height: 320)..clear(img.ColorRgb8(240, 240, 230)),
        x: 200, y: 160, radius: 100, color: img.ColorRgb8(200, 40, 40)),
  );

  test('a page has lines around the disc, paper, and the disc as its own region', () async {
    final engine = TeedLineArtEngine(() async => weights, size: 512);
    for (final style in ArtStyle.values) {
      final page = await engine.convert(photo, style, DetailLevel.simple);
      expect((page.width, page.height), (512, 410), reason: '$style');
      expect(page.lines.where((v) => v == 0), isNotEmpty, reason: '$style');
      expect(page.lines.where((v) => v == 255), isNotEmpty, reason: '$style');
      // A line on the disc's edge (radius 128 on this page), none in its middle.
      expect(page.lines[205 * 512 + 256], 255, reason: '$style');
      expect([for (var x = 256 + 112; x < 256 + 144; x++) page.lines[205 * 512 + x]].any((v) => v < 128), isTrue, reason: '$style');
      expect(page.regions.labelAt(256, 205), isNot(page.regions.labelAt(5, 5)), reason: '$style');
    }
  });

  test('cute lines are thicker than realistic ones', () async {
    final engine = TeedLineArtEngine(() async => weights, size: 512);
    int ink(LineArt page) => page.lines.where((v) => v < 128).length;
    final realistic = await engine.convert(photo, ArtStyle.realistic, DetailLevel.simple);
    final cute = await engine.convert(photo, ArtStyle.cute, DetailLevel.simple);
    expect(ink(cute), greaterThan(ink(realistic)));
  });

  test('the weights load once and both styles share one edge map', () async {
    var loads = 0;
    final engine = TeedLineArtEngine(() async {
      loads++;
      return weights;
    }, size: 256);
    final pages = await Future.wait([for (final style in ArtStyle.values) engine.convert(photo, style, DetailLevel.simple)]);
    expect(pages, hasLength(2));
    expect(loads, 1);
  });

  test('when the weights fail to load once, the next photo tries again', () async {
    var loads = 0;
    final engine = TeedLineArtEngine(() async {
      if (++loads == 1) throw const FileSystemException('busy');
      return weights;
    }, size: 256);
    await expectLater(engine.convert(photo, ArtStyle.realistic, DetailLevel.simple), throwsA(anything));
    final page = await engine.convert(photo, ArtStyle.realistic, DetailLevel.simple);
    expect(page.lines, isNotEmpty);
    expect(loads, 2);
  });

  test('rejects data that is not an image', () {
    final engine = TeedLineArtEngine(() async => weights);
    expect(engine.convert(photo.sublist(0, 10), ArtStyle.realistic, DetailLevel.simple), throwsA(anything));
  });
}
