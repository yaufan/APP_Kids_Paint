import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kids_paint/features/lineart/line_art.dart';
import 'package:kids_paint/features/lineart/simple_engine.dart';

void main() {
  // A dark disc on a light background: one subject, easy to outline.
  final photo = img.encodePng(
    img.fillCircle(img.Image(width: 200, height: 160)..clear(img.ColorRgb8(240, 240, 230)),
        x: 100, y: 80, radius: 50, color: img.ColorRgb8(200, 40, 40)),
  );

  for (final style in ArtStyle.values) {
    test('$style page has lines, paper and at least two regions', () {
      final page = SimpleLineArtEngine.convertSync(photo, style, DetailLevel.simple, size: 256);
      expect(page.width, 256);
      expect(page.height, 205);
      expect(page.lines.where((v) => v == 0), isNotEmpty);
      expect(page.lines.where((v) => v == 255), isNotEmpty);
      // The disc's inside and the background are separate fill regions.
      expect(page.regions.labelAt(128, 102), isNot(page.regions.labelAt(5, 5)));
    });
  }

  test('rejects data that is not an image', () {
    expect(
      () => SimpleLineArtEngine.convertSync(photo.sublist(0, 10), ArtStyle.realistic, DetailLevel.simple),
      throwsA(anything),
    );
  });
}
