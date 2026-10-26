import 'dart:math' as math;
import 'dart:typed_data';

/// Small image operations for turning an edge map into coloring-book lines,
/// on one-channel images stored row by row.

/// Median of each channel of an RGB image (3 bytes per pixel) over a
/// (2 * [radius] + 1) square: wipes out fine texture (fur, grain, print)
/// while edges stay where they are. A sliding histogram per channel keeps
/// it O(radius) per pixel.
Uint8List median(Uint8List rgb, int w, int h, {int radius = 3}) {
  final out = Uint8List(rgb.length);
  final hist = Int32List(256);
  final half = ((2 * radius + 1) * (2 * radius + 1)) ~/ 2;
  for (var c = 0; c < 3; c++) {
    for (var y = 0; y < h; y++) {
      hist.fillRange(0, 256, 0);
      int at(int x, int yy) => rgb[(yy.clamp(0, h - 1) * w + x.clamp(0, w - 1)) * 3 + c];
      for (var dy = -radius; dy <= radius; dy++) {
        for (var dx = -radius; dx <= radius; dx++) {
          hist[at(dx, y + dy)]++;
        }
      }
      for (var x = 0; x < w; x++) {
        if (x > 0) {
          for (var dy = -radius; dy <= radius; dy++) {
            hist[at(x - radius - 1, y + dy)]--;
            hist[at(x + radius, y + dy)]++;
          }
        }
        var v = 0, count = hist[0];
        while (count <= half) {
          count += hist[++v];
        }
        out[(y * w + x) * 3 + c] = v;
      }
    }
  }
  return out;
}

/// Edge-preserving smoothing of an RGB image (3 bytes per pixel): flattens
/// texture such as wood grain or fabric but keeps outlines sharp.
Uint8List bilateral(Uint8List rgb, int w, int h, {int radius = 4, double sigmaColor = 40, double sigmaSpace = 5}) {
  final out = Uint8List(rgb.length);
  final space = <(int, int, double)>[];
  for (var dy = -radius; dy <= radius; dy++) {
    for (var dx = -radius; dx <= radius; dx++) {
      final d2 = dx * dx + dy * dy;
      if (d2 <= radius * radius) space.add((dx, dy, math.exp(-d2 / (2 * sigmaSpace * sigmaSpace))));
    }
  }
  // Color distance is the sum of the three channel differences, as in OpenCV.
  final color = Float64List(3 * 255 + 1);
  for (var i = 0; i < color.length; i++) {
    color[i] = math.exp(-i * i / (2 * sigmaColor * sigmaColor));
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final c = (y * w + x) * 3;
      final r0 = rgb[c], g0 = rgb[c + 1], b0 = rgb[c + 2];
      var sr = 0.0, sg = 0.0, sb = 0.0, sw = 0.0;
      for (final (dx, dy, ws) in space) {
        final nx = (x + dx).clamp(0, w - 1), ny = (y + dy).clamp(0, h - 1);
        final n = (ny * w + nx) * 3;
        final r = rgb[n], g = rgb[n + 1], b = rgb[n + 2];
        final k = ws * color[(r - r0).abs() + (g - g0).abs() + (b - b0).abs()];
        sr += k * r;
        sg += k * g;
        sb += k * b;
        sw += k;
      }
      out[c] = (sr / sw).round();
      out[c + 1] = (sg / sw).round();
      out[c + 2] = (sb / sw).round();
    }
  }
  return out;
}

/// Pixels above [low] that are connected (8 neighbours) to a pixel above
/// [high]: strong edges plus the weaker parts that continue them.
Uint8List hysteresis(Float32List edges, int w, int h, double low, double high) {
  final out = Uint8List(edges.length);
  final stack = <int>[];
  for (var start = 0; start < edges.length; start++) {
    if (edges[start] <= high || out[start] == 1) continue;
    out[start] = 1;
    stack.add(start);
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % w, y = i ~/ w;
      for (var dy = -1; dy <= 1; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= h) continue;
        for (var dx = -1; dx <= 1; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= w) continue;
          final j = ny * w + nx;
          if (out[j] == 0 && edges[j] > low) {
            out[j] = 1;
            stack.add(j);
          }
        }
      }
    }
  }
  return out;
}

/// Square dilation of a 0/1 mask by [r] pixels, in O(n) per axis.
Uint8List dilate(Uint8List mask, int w, int h, int r) {
  if (r <= 0) return Uint8List.fromList(mask);
  final rows = Uint8List(mask.length);
  final prefix = Int32List(math.max(w, h) + 1);
  for (var y = 0; y < h; y++) {
    final row = y * w;
    for (var x = 0; x < w; x++) {
      prefix[x + 1] = prefix[x] + mask[row + x];
    }
    for (var x = 0; x < w; x++) {
      if (prefix[math.min(w, x + r + 1)] - prefix[math.max(0, x - r)] > 0) rows[row + x] = 1;
    }
  }
  final out = Uint8List(mask.length);
  for (var x = 0; x < w; x++) {
    for (var y = 0; y < h; y++) {
      prefix[y + 1] = prefix[y] + rows[y * w + x];
    }
    for (var y = 0; y < h; y++) {
      if (prefix[math.min(h, y + r + 1)] - prefix[math.max(0, y - r)] > 0) out[y * w + x] = 1;
    }
  }
  return out;
}

/// Thins a 0/1 mask in place to lines one pixel wide (Zhang and Suen, 1984).
Uint8List thin(Uint8List mask, int w, int h) {
  // Outer pixels are cleared so every pixel checked has 8 neighbours.
  for (var x = 0; x < w; x++) {
    mask[x] = 0;
    mask[(h - 1) * w + x] = 0;
  }
  for (var y = 0; y < h; y++) {
    mask[y * w] = 0;
    mask[y * w + w - 1] = 0;
  }
  var candidates = [for (var i = 0; i < mask.length; i++) if (mask[i] == 1) i];
  final remove = <int>[];
  var changed = true;
  while (changed) {
    changed = false;
    for (var pass = 0; pass < 2; pass++) {
      remove.clear();
      for (final i in candidates) {
        if (mask[i] == 0) continue;
        // Neighbours clockwise from the top: p2 .. p9.
        final p2 = mask[i - w], p3 = mask[i - w + 1], p4 = mask[i + 1], p5 = mask[i + w + 1];
        final p6 = mask[i + w], p7 = mask[i + w - 1], p8 = mask[i - 1], p9 = mask[i - w - 1];
        final b = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9;
        if (b < 2 || b > 6) continue;
        final a = (p2 == 0 && p3 == 1 ? 1 : 0) + (p3 == 0 && p4 == 1 ? 1 : 0) + (p4 == 0 && p5 == 1 ? 1 : 0) +
            (p5 == 0 && p6 == 1 ? 1 : 0) + (p6 == 0 && p7 == 1 ? 1 : 0) + (p7 == 0 && p8 == 1 ? 1 : 0) +
            (p8 == 0 && p9 == 1 ? 1 : 0) + (p9 == 0 && p2 == 1 ? 1 : 0);
        if (a != 1) continue;
        if (pass == 0 ? (p2 * p4 * p6 != 0 || p4 * p6 * p8 != 0) : (p2 * p4 * p8 != 0 || p2 * p6 * p8 != 0)) continue;
        remove.add(i);
      }
      for (final i in remove) {
        mask[i] = 0;
      }
      if (remove.isNotEmpty) changed = true;
    }
    candidates = [for (final i in candidates) if (mask[i] == 1) i];
  }
  return mask;
}

/// Clears connected groups (8 neighbours) of fewer than [minPixels] pixels.
Uint8List dropSmall(Uint8List mask, int w, int h, int minPixels) {
  final seen = Uint8List(mask.length);
  final stack = <int>[], members = <int>[];
  for (var start = 0; start < mask.length; start++) {
    if (mask[start] == 0 || seen[start] == 1) continue;
    members.clear();
    seen[start] = 1;
    stack.add(start);
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      members.add(i);
      final x = i % w, y = i ~/ w;
      for (var dy = -1; dy <= 1; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= h) continue;
        for (var dx = -1; dx <= 1; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= w) continue;
          final j = ny * w + nx;
          if (mask[j] == 1 && seen[j] == 0) {
            seen[j] = 1;
            stack.add(j);
          }
        }
      }
    }
    if (members.length < minPixels) {
      for (final i in members) {
        mask[i] = 0;
      }
    }
  }
  return mask;
}

/// Draws one-pixel center lines from a [w] x [h] grid as even, round,
/// anti-aliased strokes [thickness] wide on a [pageW] x [pageH] page.
///
/// Each point is first moved to the average of the line points around it,
/// which irons out the stair steps of the small grid, then neighbouring
/// points are joined by capsules. Returns ink coverage, 0 (paper) to 1.
Float32List strokes(Uint8List center, int w, int h, int pageW, int pageH, double thickness) {
  final sx = pageW / w, sy = pageH / h;
  final px = Float32List(center.length), py = Float32List(center.length);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (center[i] == 0) continue;
      var ax = 0.0, ay = 0.0, n = 0;
      for (var dy = -2; dy <= 2; dy++) {
        final ny = y + dy;
        if (ny < 0 || ny >= h) continue;
        for (var dx = -2; dx <= 2; dx++) {
          final nx = x + dx;
          if (nx < 0 || nx >= w || center[ny * w + nx] == 0) continue;
          ax += nx;
          ay += ny;
          n++;
        }
      }
      px[i] = ((ax / n + 0.5) * sx);
      py[i] = ((ay / n + 0.5) * sy);
    }
  }
  final ink = Float32List(pageW * pageH);
  final r = thickness / 2;
  void capsule(double ax, double ay, double bx, double by) {
    final x0 = math.max(0, (math.min(ax, bx) - r - 1).floor()), x1 = math.min(pageW - 1, (math.max(ax, bx) + r + 1).ceil());
    final y0 = math.max(0, (math.min(ay, by) - r - 1).floor()), y1 = math.min(pageH - 1, (math.max(ay, by) + r + 1).ceil());
    final dx = bx - ax, dy = by - ay, len2 = dx * dx + dy * dy;
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final qx = x + 0.5 - ax, qy = y + 0.5 - ay;
        final t = len2 == 0 ? 0.0 : ((qx * dx + qy * dy) / len2).clamp(0.0, 1.0);
        final ex = qx - t * dx, ey = qy - t * dy;
        final cover = (r + 0.5 - math.sqrt(ex * ex + ey * ey)).clamp(0.0, 1.0);
        final k = y * pageW + x;
        if (cover > ink[k]) ink[k] = cover;
      }
    }
  }

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (center[i] == 0) continue;
      var joined = false;
      // Join to the neighbours after this one (right, and the row below).
      for (final (dx, dy) in const [(1, 0), (-1, 1), (0, 1), (1, 1)]) {
        final nx = x + dx, ny = y + dy;
        if (nx < 0 || nx >= w || ny >= h) continue;
        final j = ny * w + nx;
        if (center[j] == 0) continue;
        capsule(px[i], py[i], px[j], py[j]);
        joined = true;
      }
      if (!joined) capsule(px[i], py[i], px[i], py[i]);
    }
  }
  return ink;
}

/// Separable Gaussian blur.
Float32List gaussianBlur(Float32List src, int w, int h, double sigma) {
  final r = (3 * sigma).ceil();
  final kernel = Float32List(2 * r + 1);
  var sum = 0.0;
  for (var i = -r; i <= r; i++) {
    sum += kernel[i + r] = math.exp(-i * i / (2 * sigma * sigma));
  }
  for (var i = 0; i < kernel.length; i++) {
    kernel[i] /= sum;
  }
  final tmp = Float32List(src.length), out = Float32List(src.length);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var s = 0.0;
      for (var k = -r; k <= r; k++) {
        s += kernel[k + r] * src[y * w + (x + k).clamp(0, w - 1)];
      }
      tmp[y * w + x] = s;
    }
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var s = 0.0;
      for (var k = -r; k <= r; k++) {
        s += kernel[k + r] * tmp[(y + k).clamp(0, h - 1) * w + x];
      }
      out[y * w + x] = s;
    }
  }
  return out;
}

/// Distance from each pixel of a 0/1 mask to the nearest 0 pixel (exact,
/// Felzenszwalb and Huttenlocher); 0 outside the mask.
Float32List distanceInside(Uint8List mask, int w, int h) {
  const inf = 1e12;
  final d = Float64List(mask.length);
  for (var i = 0; i < mask.length; i++) {
    d[i] = mask[i] == 0 ? 0 : inf;
  }
  final n = math.max(w, h);
  final f = Float64List(n), z = Float64List(n + 1), out = Float64List(n);
  final v = Int32List(n);
  void pass1d(int len) {
    var k = 0;
    v[0] = 0;
    z[0] = -inf;
    z[1] = inf;
    for (var q = 1; q < len; q++) {
      var s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]);
      while (s <= z[k]) {
        k--;
        s = ((f[q] + q * q) - (f[v[k]] + v[k] * v[k])) / (2 * q - 2 * v[k]);
      }
      k++;
      v[k] = q;
      z[k] = s;
      z[k + 1] = inf;
    }
    k = 0;
    for (var q = 0; q < len; q++) {
      while (z[k + 1] < q) {
        k++;
      }
      out[q] = (q - v[k]) * (q - v[k]) + f[v[k]];
    }
  }

  for (var x = 0; x < w; x++) {
    for (var y = 0; y < h; y++) {
      f[y] = d[y * w + x];
    }
    pass1d(h);
    for (var y = 0; y < h; y++) {
      d[y * w + x] = out[y];
    }
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      f[x] = d[y * w + x];
    }
    pass1d(w);
    for (var x = 0; x < w; x++) {
      d[y * w + x] = out[x];
    }
  }
  return Float32List.fromList([for (final s in d) math.sqrt(s)]);
}
