import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A drawing a child made on paper, as it comes out of a photo of it.
typedef PaperDrawing = ({Uint8List png, int width, int height});

/// A photo of a child's drawing on paper, cleaned up (0.18): the sheet is
/// found and cut out of the table around it, the paper becomes
/// see-through (its shadows and the lamp's yellow go with it) and the
/// drawing's colors are made a little stronger. Cropped close around the
/// drawing. Null when the photo cannot be read or nothing is drawn on it.
PaperDrawing? paperDrawing(Uint8List photo, {int maxSide = 800}) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(photo);
  } on Object {
    decoded = null; // not a picture the decoder knows
  }
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  final shrink = maxSide / math.max(image.width, image.height);
  if (shrink < 1) {
    image = img.copyResize(image,
        width: math.max(1, (image.width * shrink).round()),
        height: math.max(1, (image.height * shrink).round()),
        interpolation: img.Interpolation.average);
  }
  final w = image.width, h = image.height;
  final rgb = Float32List(w * h * 3), lum = Float32List(w * h);
  for (final p in image) {
    final i = p.y * w + p.x;
    final r = p.rNormalized.toDouble(), g = p.gNormalized.toDouble(), b = p.bNormalized.toDouble();
    rgb[i * 3] = r;
    rgb[i * 3 + 1] = g;
    rgb[i * 3 + 2] = b;
    lum[i] = 0.299 * r + 0.587 * g + 0.114 * b;
  }

  final sheet = _sheet(lum, w, h);
  final drawing = _clean(rgb, lum, w, sheet);
  if (drawing == null) return null;
  final png = img.encodePng(drawing);
  return (png: png, width: drawing.width, height: drawing.height);
}

/// The sheet of paper: the biggest bright patch (a table or a floor around
/// it is darker), a little inside its edge. The whole photo when no patch
/// is big enough (the sheet fills the photo, or it is not a sheet at all).
({int x0, int y0, int x1, int y1}) _sheet(Float32List lum, int w, int h) {
  const step = 4;
  final gw = w ~/ step, gh = h ~/ step;
  final whole = (x0: 0, y0: 0, x1: w, y1: h);
  if (gw < 8 || gh < 8) return whole;
  final cells = Float32List(gw * gh);
  for (var y = 0; y < gh; y++) {
    for (var x = 0; x < gw; x++) {
      cells[y * gw + x] = lum[(y * step) * w + x * step];
    }
  }
  final threshold = _otsu(cells);
  final label = Int32List(gw * gh);
  var best = 0, bestSize = 0;
  ({int x0, int y0, int x1, int y1})? box;
  final queue = <int>[];
  var next = 0;
  for (var start = 0; start < cells.length; start++) {
    if (label[start] != 0 || cells[start] <= threshold) continue;
    next++;
    var size = 0, x0 = gw, y0 = gh, x1 = 0, y1 = 0;
    queue
      ..clear()
      ..add(start);
    label[start] = next;
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      size++;
      final x = i % gw, y = i ~/ gw;
      x0 = math.min(x0, x);
      x1 = math.max(x1, x);
      y0 = math.min(y0, y);
      y1 = math.max(y1, y);
      for (final j in [if (x > 0) i - 1, if (x < gw - 1) i + 1, if (y > 0) i - gw, if (y < gh - 1) i + gw]) {
        if (label[j] == 0 && cells[j] > threshold) {
          label[j] = next;
          queue.add(j);
        }
      }
    }
    if (size > bestSize) {
      best = next;
      bestSize = size;
      box = (x0: x0, y0: y0, x1: x1 + 1, y1: y1 + 1);
    }
  }
  if (best == 0 || bestSize < cells.length * 0.2) return whole;
  final b = box!;
  // A little inside the edge, where the sheet's own shadow is.
  final ix = ((b.x1 - b.x0) * step * 0.02).round(), iy = ((b.y1 - b.y0) * step * 0.02).round();
  return (
    x0: math.min(w - 1, b.x0 * step + ix),
    y0: math.min(h - 1, b.y0 * step + iy),
    x1: math.max(b.x0 * step + ix + 1, math.min(w, b.x1 * step - ix)),
    y1: math.max(b.y0 * step + iy + 1, math.min(h, b.y1 * step - iy)),
  );
}

/// The threshold that best splits [values] (0..1) in two (Otsu's method).
double _otsu(Float32List values) {
  final hist = List<int>.filled(64, 0);
  for (final v in values) {
    hist[(v.clamp(0, 1) * 63).round()]++;
  }
  final total = values.length;
  var sum = 0.0;
  for (var i = 0; i < 64; i++) {
    sum += i * hist[i];
  }
  var sumB = 0.0, wB = 0, best = 0.0, threshold = 32;
  for (var i = 0; i < 64; i++) {
    wB += hist[i];
    if (wB == 0) continue;
    final wF = total - wB;
    if (wF == 0) break;
    sumB += i * hist[i];
    final mB = sumB / wB, mF = (sum - sumB) / wF;
    final between = wB * wF * (mB - mF) * (mB - mF);
    if (between > best) {
      best = between;
      threshold = i;
    }
  }
  return threshold / 63;
}

/// Inside [sheet]: the paper see-through, the drawing kept, cropped close.
img.Image? _clean(Float32List rgb, Float32List lum, int w, ({int x0, int y0, int x1, int y1}) sheet) {
  final sw = sheet.x1 - sheet.x0, sh = sheet.y1 - sheet.y0;
  // The paper's own color, tile by tile: the brighter pixels of each tile.
  const tile = 32;
  final tw = (sw / tile).ceil(), th = (sh / tile).ceil();
  final paper = Float32List(tw * th * 3), paperLum = Float32List(tw * th);
  for (var ty = 0; ty < th; ty++) {
    for (var tx = 0; tx < tw; tx++) {
      final ls = <double>[];
      for (var y = sheet.y0 + ty * tile; y < math.min(sheet.y1, sheet.y0 + (ty + 1) * tile); y++) {
        for (var x = sheet.x0 + tx * tile; x < math.min(sheet.x1, sheet.x0 + (tx + 1) * tile); x++) {
          ls.add(lum[y * w + x]);
        }
      }
      ls.sort();
      final cut = ls[(ls.length * 0.8).floor().clamp(0, ls.length - 1)];
      var r = 0.0, g = 0.0, b = 0.0, n = 0;
      for (var y = sheet.y0 + ty * tile; y < math.min(sheet.y1, sheet.y0 + (ty + 1) * tile); y++) {
        for (var x = sheet.x0 + tx * tile; x < math.min(sheet.x1, sheet.x0 + (tx + 1) * tile); x++) {
          final i = y * w + x;
          if (lum[i] < cut) continue;
          r += rgb[i * 3];
          g += rgb[i * 3 + 1];
          b += rgb[i * 3 + 2];
          n++;
        }
      }
      final k = ty * tw + tx;
      paper[k * 3] = r / n;
      paper[k * 3 + 1] = g / n;
      paper[k * 3 + 2] = b / n;
      paperLum[k] = cut;
    }
  }
  // A tile all drawn over has no paper to see: it takes its brightest
  // neighbor's, or the sheet's usual paper.
  final sorted = Float32List.fromList(paperLum)..sort();
  final usual = sorted[sorted.length ~/ 2];
  final fixed = Float32List.fromList(paper);
  for (var ty = 0; ty < th; ty++) {
    for (var tx = 0; tx < tw; tx++) {
      var pick = ty * tw + tx;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = tx + dx, ny = ty + dy;
          if (nx < 0 || ny < 0 || nx >= tw || ny >= th) continue;
          if (paperLum[ny * tw + nx] > paperLum[pick]) pick = ny * tw + nx;
        }
      }
      final k = ty * tw + tx;
      final source = paperLum[pick] < usual * 0.75 ? null : pick;
      for (var c = 0; c < 3; c++) {
        fixed[k * 3 + c] = source == null ? usual : paper[source * 3 + c];
      }
    }
  }

  final out = img.Image(width: sw, height: sh, numChannels: 4);
  var x0 = sw, y0 = sh, x1 = -1, y1 = -1, inked = 0;
  for (var y = 0; y < sh; y++) {
    // Between tile centers, smoothly.
    final fy = ((y + 0.5) / tile - 0.5).clamp(0.0, th - 1.0);
    final ty0 = fy.floor(), ty1 = math.min(th - 1, ty0 + 1);
    final ay = fy - ty0;
    for (var x = 0; x < sw; x++) {
      final fx = ((x + 0.5) / tile - 0.5).clamp(0.0, tw - 1.0);
      final tx0 = fx.floor(), tx1 = math.min(tw - 1, tx0 + 1);
      final ax = fx - tx0;
      final i = (sheet.y0 + y) * w + sheet.x0 + x;
      final c = <double>[0, 0, 0];
      for (var k = 0; k < 3; k++) {
        final top = fixed[(ty0 * tw + tx0) * 3 + k] * (1 - ax) + fixed[(ty0 * tw + tx1) * 3 + k] * ax;
        final bottom = fixed[(ty1 * tw + tx0) * 3 + k] * (1 - ax) + fixed[(ty1 * tw + tx1) * 3 + k] * ax;
        final p = math.max(0.05, top * (1 - ay) + bottom * ay);
        c[k] = math.min(1.0, rgb[i * 3 + k] / p);
      }
      final l = 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2];
      final sat = c.reduce(math.max) - c.reduce(math.min);
      final ink = math.max(1 - l, sat * 1.4);
      final alpha = _smoothstep(0.1, 0.22, ink);
      if (alpha == 0) continue;
      // Pencil and crayon on paper look faint in a photo: a little stronger.
      final mean = (c[0] + c[1] + c[2]) / 3;
      final r = math.pow((mean + (c[0] - mean) * 1.35).clamp(0.0, 1.0), 1.3);
      final g = math.pow((mean + (c[1] - mean) * 1.35).clamp(0.0, 1.0), 1.3);
      final b = math.pow((mean + (c[2] - mean) * 1.35).clamp(0.0, 1.0), 1.3);
      out.setPixelRgba(x, y, (r * 255).round(), (g * 255).round(), (b * 255).round(), (alpha * 255).round());
      if (alpha > 0.5) {
        inked++;
        x0 = math.min(x0, x);
        y0 = math.min(y0, y);
        x1 = math.max(x1, x);
        y1 = math.max(y1, y);
      }
    }
  }
  // A tilted sheet leaves bits of the table in the corners: whatever is
  // drawn there and runs off the edge, only near the edge, goes.
  inked -= _clearEdges(out, (math.max(sw, sh) * 0.05).round());
  x0 = sw;
  y0 = sh;
  x1 = -1;
  y1 = -1;
  for (final p in out) {
    if (p.a <= 127) continue;
    x0 = math.min(x0, p.x);
    y0 = math.min(y0, p.y);
    x1 = math.max(x1, p.x);
    y1 = math.max(y1, p.y);
  }
  if (inked < sw * sh * 0.002 || x1 < 0) return null;
  // Close around the drawing, with a little paper to spare.
  final pad = (math.max(x1 - x0, y1 - y0) * 0.04).round() + 2;
  final cx0 = math.max(0, x0 - pad), cy0 = math.max(0, y0 - pad);
  return img.copyCrop(out, x: cx0, y: cy0, width: math.min(sw, x1 + pad + 1) - cx0, height: math.min(sh, y1 + pad + 1) - cy0);
}

/// Makes see-through what is not see-through, touches [image]'s edge and
/// is within [band] of it; returns how many solid pixels went.
int _clearEdges(img.Image image, int band) {
  final w = image.width, h = image.height;
  bool near(int x, int y) => x < band || y < band || x >= w - band || y >= h - band;
  final seen = Uint8List(w * h);
  final queue = <int>[];
  for (var x = 0; x < w; x++) {
    queue..add(x)..add((h - 1) * w + x);
  }
  for (var y = 0; y < h; y++) {
    queue..add(y * w)..add(y * w + w - 1);
  }
  var cleared = 0;
  while (queue.isNotEmpty) {
    final i = queue.removeLast();
    if (seen[i] == 1) continue;
    seen[i] = 1;
    final x = i % w, y = i ~/ w;
    final p = image.getPixel(x, y);
    if (p.a == 0 || !near(x, y)) continue;
    if (p.a > 127) cleared++;
    p.a = 0;
    if (x > 0) queue.add(i - 1);
    if (x < w - 1) queue.add(i + 1);
    if (y > 0) queue.add(i - w);
    if (y < h - 1) queue.add(i + w);
  }
  return cleared;
}

double _smoothstep(double a, double b, double x) {
  final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}
