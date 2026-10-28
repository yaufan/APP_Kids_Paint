import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Grayscale page pixels -> a GPU image the canvas can draw.
Future<ui.Image> grayToImage(Uint8List gray, int width, int height) {
  final rgba = Uint8List(width * height * 4);
  for (var i = 0; i < gray.length; i++) {
    final g = gray[i];
    rgba[i * 4] = g;
    rgba[i * 4 + 1] = g;
    rgba[i * 4 + 2] = g;
    rgba[i * 4 + 3] = 255;
  }
  return rgbaToImage(rgba, width, height);
}

Future<ui.Image> rgbaToImage(Uint8List rgba, int width, int height) {
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, done.complete);
  return done.future;
}

/// Shows grayscale page pixels, e.g. a style preview.
class GrayPagePreview extends StatefulWidget {
  const GrayPagePreview({super.key, required this.gray, required this.width, required this.height});

  final Uint8List gray;
  final int width;
  final int height;

  @override
  State<GrayPagePreview> createState() => _GrayPagePreviewState();
}

class _GrayPagePreviewState extends State<GrayPagePreview> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    grayToImage(widget.gray, widget.width, widget.height).then((image) {
      if (mounted) {
        setState(() => _image = image);
      } else {
        image.dispose();
      }
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AspectRatio(aspectRatio: widget.width / widget.height, child: RawImage(image: _image, fit: BoxFit.contain));
}

/// Color layer underneath, line art multiplied on top: lines never get covered.
class PagePainter extends CustomPainter {
  PagePainter({required this.colors, required this.lines});

  final ui.Image? colors;
  final ui.Image lines;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    final src = Rect.fromLTWH(0, 0, lines.width.toDouble(), lines.height.toDouble());
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (colors != null) {
      canvas.drawImageRect(colors!, src, dst, paint);
    } else {
      canvas.drawRect(dst, Paint()..color = Colors.white);
    }
    canvas.drawImageRect(lines, src, dst, paint..blendMode = BlendMode.multiply);
  }

  @override
  bool shouldRepaint(PagePainter old) => old.colors != colors || old.lines != lines;
}
