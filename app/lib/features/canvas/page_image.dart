import 'dart:async';
import 'dart:math' as math;
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
  PagePainter({required this.colors, required this.lines, this.view});

  final ui.Image? colors;
  final ui.Image lines;

  /// The part of the page shown, in page pixels (all of it when null): the
  /// canvas shows the drawing without the empty paper round it, or zoomed in.
  final Rect? view;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Offset.zero & size;
    final src = view ?? Rect.fromLTWH(0, 0, lines.width.toDouble(), lines.height.toDouble());
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (colors != null) {
      canvas.drawImageRect(colors!, src, dst, paint);
    } else {
      canvas.drawRect(dst, Paint()..color = Colors.white);
    }
    canvas.drawImageRect(lines, src, dst, paint..blendMode = BlendMode.multiply);
  }

  @override
  bool shouldRepaint(PagePainter old) => old.colors != colors || old.lines != lines || old.view != view;
}

/// The part of a page worth looking at while coloring it: its line art
/// with a little paper round it, grown to the page's shape and kept on the
/// page. All of the page when there are no lines or they nearly fill it.
Rect pageFit(Uint8List lines, int width, int height) {
  final whole = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  var x0 = width, y0 = height, x1 = -1, y1 = -1;
  for (var y = 0; y < height; y++) {
    final row = y * width;
    for (var x = 0; x < width; x++) {
      if (lines[row + x] >= 128) continue;
      if (x < x0) x0 = x;
      if (x > x1) x1 = x;
      if (y < y0) y0 = y;
      y1 = y;
    }
  }
  if (x1 < 0) return whole;
  final margin = 0.04 * math.max(width, height);
  final box = Rect.fromLTRB(x0 - margin, y0 - margin, x1 + 1 + margin, y1 + 1 + margin);
  final aspect = width / height;
  final w = box.width / box.height < aspect ? box.height * aspect : box.width;
  if (w > width / 1.02) return whole;
  final fit = Rect.fromCenter(center: box.center, width: w, height: w / aspect);
  final dx = fit.left < 0 ? -fit.left : (fit.right > width ? width - fit.right : 0.0);
  final dy = fit.top < 0 ? -fit.top : (fit.bottom > height ? height - fit.bottom : 0.0);
  return fit.shift(Offset(dx, dy));
}
