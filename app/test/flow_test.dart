import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../integration_test/walkthrough.dart';

/// The app walk-through on headless phone and tablet screens; screenshots go
/// to `build/screenshots/<device>/`. The same walk-through runs on iPhone and iPad
/// simulators from `integration_test/app_flow_test.dart`.
void main() {
  Future<void> loadFonts() async {
    // Real fonts instead of the test font's boxes, when they are available.
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '';
    final fonts = {
      'MaterialIcons': ['$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf'],
      // The app's own font, also standing in for widgets that ask for Roboto.
      'Huninn': ['assets/fonts/jf-openhuninn-2.1.ttf'],
      'Roboto': ['assets/fonts/jf-openhuninn-2.1.ttf'],
      'Noto Color Emoji': ['/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf'], // avatars
    };
    for (final MapEntry(key: family, value: paths) in fonts.entries) {
      final loader = FontLoader(family);
      for (final path in paths.where((p) => File(p).existsSync())) {
        loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
      }
      await loader.load();
    }
  }

  // A common Android phone (portrait) and a 10-inch tablet (landscape).
  for (final (device, size, ratio) in [
    ('phone', const Size(1080, 2340), 2.75),
    ('tablet', const Size(2560, 1600), 2.0),
  ]) {
    testWidgets('$device: a child makes a coloring page, colors it and finds it in the gallery', (tester) async {
      await tester.runAsync(loadFonts);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      await runWalkthrough(
        tester,
        photo: File('test/assets/coffee.jpg').readAsBytesSync(),
        shot: (name) => tester.runAsync(() async {
          final boundary = walkthroughKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          File('build/screenshots/$device/$name.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!.buffer.asUint8List());
        }),
      );
    }, timeout: const Timeout(Duration(minutes: 9)));
  }
}
