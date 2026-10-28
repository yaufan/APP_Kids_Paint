import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'line_art.dart';
import 'raster.dart' as raster;
import 'region_map.dart';
import 'teed.dart';

/// Where the outlines of a photo are, from the TEED network.
class EdgeMap {
  EdgeMap(this.width, this.height, this.edges, this.pageWidth, this.pageHeight);

  /// Size of the map; the network ran at this size.
  final int width;
  final int height;

  /// Edge strength per pixel, 0 (none) to 1 (the strongest in the photo).
  final Float32List edges;

  /// Size of the coloring page made from it, the photo's shape.
  final int pageWidth;
  final int pageHeight;
}

/// Turns a photo into a coloring page whose lines follow the photo's real
/// outlines, as in `prototypes/lineart` (which used the bigger DexiNed):
///
/// 1. smooth texture away (median, then bilateral filter) and let TEED find
///    the edges;
/// 2. keep strong edges and the weaker parts that continue them (edges well
///    inside skin count for less, so wrinkles do not become lines), thin
///    them to center lines and drop short scraps, little enclosed bits too
///    small to color, and the photo's own border;
/// 3. draw the center lines as even, round strokes on the page; the cute
///    style uses fewer, thicker lines and melts them into rounder shapes;
/// 4. compute fill regions that do not leak through the small gaps left.
///
/// Everything runs on the phone, in Dart, in a background isolate.
class TeedLineArtEngine implements LineArtEngine {
  TeedLineArtEngine(this._loadWeights, {this.size = 1024, this.edgeSize = 480});

  final Future<Uint8List> Function() _loadWeights;

  /// Long side of the produced page, in pixels.
  final int size;

  /// Long side of the image the network looks at.
  final int edgeSize;

  /// How much an edge well inside skin counts (wrinkles, freckles). Lower
  /// also wipes out a ginger cat's whiskers, which look like skin.
  static const insideSkin = 0.6;

  Future<Uint8List>? _weights;
  (Uint8List, Future<EdgeMap>)? _last;

  @override
  Future<LineArt> convert(Uint8List photo, ArtStyle style, DetailLevel detail) async {
    final edges = await _edgesOf(photo);
    return Isolate.run(() => pageFrom(edges, style, detail));
  }

  /// Both styles are made from the same photo, so its edges are kept.
  Future<EdgeMap> _edgesOf(Uint8List photo) {
    final last = _last;
    if (last != null && identical(last.$1, photo)) return last.$2;
    final weights = _weights ??= _loadWeights().catchError((Object e) {
      _weights = null; // try again next time
      throw e;
    });
    final edges = weights.then((w) => _edgesInIsolate(photo, w, size, edgeSize));
    _last = (photo, edges);
    // If it fails, the same photo is tried afresh next time.
    edges.then<void>((_) {}, onError: (Object _) {
      if (identical(_last?.$2, edges)) _last = null;
    });
    return edges;
  }

  /// [edgeMapOf] on another isolate. Its own function, so the closure sent
  /// there carries only what it needs (not the futures around the call).
  static Future<EdgeMap> _edgesInIsolate(Uint8List photo, Uint8List weights, int size, int edgeSize) =>
      Isolate.run(() => edgeMapOf(photo, Teed.decode(weights), size: size, edgeSize: edgeSize));

  /// Decodes [photo] and finds its edges.
  static EdgeMap edgeMapOf(Uint8List photo, Teed teed, {int size = 1024, int edgeSize = 480}) {
    final decoded = img.decodeImage(photo);
    if (decoded == null) throw const FormatException('unsupported image');
    final image = img.bakeOrientation(decoded);
    final long = math.max(image.width, image.height);
    final pageW = math.max(1, (image.width * size / long).round()), pageH = math.max(1, (image.height * size / long).round());
    // The network needs sides that are multiples of 8.
    final s = edgeSize / long;
    final w = math.max(8, (image.width * s / 8).round() * 8), h = math.max(8, (image.height * s / 8).round() * 8);
    final small = img.copyResize(image, width: w, height: h, interpolation: img.Interpolation.average);
    final rgb = Uint8List(w * h * 3);
    for (final p in small) {
      final i = (p.y * w + p.x) * 3;
      rgb[i] = p.r.toInt();
      rgb[i + 1] = p.g.toInt();
      rgb[i + 2] = p.b.toInt();
    }
    // Texture (fur, wood grain, printed patterns) would become a mesh of
    // little lines: a median filter wipes it out, a bilateral one evens
    // what is left, and outlines stay sharp through both.
    final smooth = raster.bilateral(raster.median(rgb, w, h), w, h);
    final bgr = Float32List(w * h * 3);
    for (var i = 0; i < w * h; i++) {
      bgr[3 * i] = smooth[3 * i + 2] - Teed.meanBgr[0];
      bgr[3 * i + 1] = smooth[3 * i + 1] - Teed.meanBgr[1];
      bgr[3 * i + 2] = smooth[3 * i] - Teed.meanBgr[2];
    }
    // The average of the network's three scales and their fusion is calmer
    // than the fusion alone: fewer texture lines, same outlines.
    final outs = teed.run(bgr, w, h);
    final edges = Float32List(w * h);
    var lo = double.infinity, hi = double.negativeInfinity;
    for (var i = 0; i < edges.length; i++) {
      var e = 0.0;
      for (final o in outs) {
        e += 1 / (1 + math.exp(-o[i]));
      }
      e /= outs.length;
      edges[i] = e;
      lo = math.min(lo, e);
      hi = math.max(hi, e);
    }
    final range = math.max(1e-6, hi - lo);
    // Well inside skin (a face, an arm) wrinkles, creases and freckles would
    // become a tangle of lines, so edges there count for less: only clear
    // ones still start a line. Eyes, lips and the face's outline sit where
    // skin ends, so they keep their full strength.
    final notSkin = raster.skin(smooth, w, h);
    for (var i = 0; i < notSkin.length; i++) {
      notSkin[i] = 1 - notSkin[i];
    }
    final nearOther = raster.dilate(notSkin, w, h, 2);
    for (var i = 0; i < edges.length; i++) {
      edges[i] = (edges[i] - lo) / range;
      if (nearOther[i] == 0) edges[i] *= insideSkin;
    }
    return EdgeMap(w, h, edges, pageW, pageH);
  }

  /// Draws the page for [style] and [detail] from [map].
  static LineArt pageFrom(EdgeMap map, ArtStyle style, DetailLevel detail) {
    final p = _Lines.of(style, detail);
    final w = map.width, h = map.height, pw = map.pageWidth, ph = map.pageHeight;
    final scale = math.max(pw, ph).toDouble(); // the prototype's sizes are fractions of the page

    final edges = Float32List.fromList(map.edges);
    // The network sees an edge where the photo ends; that is not a line.
    const border = 4;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (x < border || y < border || x >= w - border || y >= h - border) edges[y * w + x] = 0;
      }
    }
    // A photo with soft light (an apple on a cloth) has weak outlines
    // everywhere: then the threshold follows its strongest edges instead, so
    // the main outline still makes it onto the page.
    final strong = _percentile(edges, 0.995);
    final high = math.min(p.high, math.max(0.3, 0.9 * strong)), low = math.min(p.low, 0.4 * high);
    // No closing of small breaks here: on TEED's thin lines it knits texture
    // into a mesh. The fill regions below take care of the breaks instead.
    final center = raster.thin(raster.hysteresis(edges, w, h, low, high), w, h);
    raster.dropSmall(center, w, h, (p.strokeLength * math.sqrt(w * w + h * h)).round());
    // Little enclosed bits (too small to color on their own) would only
    // clutter the page: their fences go, then any scraps left over. Clearly
    // drawn ones (an eye, a nose) stay.
    raster.removeTinyAreas(center, edges, w, h, math.max(1, (p.minRegion * w * h).round()), keep: 0.6);
    raster.dropSmall(center, w, h, (p.strokeLength * math.sqrt(w * w + h * h)).round());
    var ink = raster.strokes(center, w, h, pw, ph, p.line * scale);
    if (style == ArtStyle.cute) ink = _round(ink, pw, ph, p.rounding * scale, p.line * scale);

    final page = Uint8List(pw * ph);
    for (var i = 0; i < page.length; i++) {
      page[i] = (255 * (1 - ink[i])).round();
    }
    final regions = RegionMap.fromLines(page, pw, ph, gap: math.max(1, (p.gap * scale).round()), minRegion: math.max(1, (p.minRegion * pw * ph).round()));
    return LineArt(width: pw, height: ph, lines: page, regions: regions);
  }

  /// The value below which a [fraction] of the edge strengths fall.
  static double _percentile(Float32List edges, double fraction) {
    final bins = Int32List(1001);
    for (final e in edges) {
      bins[(e.clamp(0.0, 1.0) * 1000).round()]++;
    }
    var count = 0;
    final target = fraction * edges.length;
    for (var b = 0; b < bins.length; b++) {
      count += bins[b];
      if (count >= target) return b / 1000;
    }
    return 1;
  }

  /// Cartoon look: wiggles and corners melt into round, chunky strokes, and
  /// where nearby lines melt into a black patch only its rim stays, so the
  /// patch becomes one simple shape to color.
  static Float32List _round(Float32List ink, int w, int h, double sigma, double line) {
    final solid = Float32List(ink.length);
    for (var i = 0; i < ink.length; i++) {
      solid[i] = ink[i] >= 0.5 ? 1 : 0;
    }
    final soft = raster.gaussianBlur(solid, w, h, sigma);
    final mask = Uint8List(ink.length);
    for (var i = 0; i < ink.length; i++) {
      mask[i] = soft[i] >= 0.5 ? 1 : 0;
    }
    final depth = raster.distanceInside(mask, w, h);
    for (var i = 0; i < ink.length; i++) {
      solid[i] = mask[i] == 1 && depth[i] <= line ? 1 : 0;
    }
    final edge = raster.gaussianBlur(solid, w, h, 1.2);
    for (var i = 0; i < edge.length; i++) {
      edge[i] = ((edge[i] - 0.5) * 4 + 0.5).clamp(0.0, 1.0);
    }
    return edge;
  }
}

/// How a page's lines are drawn. Lengths are fractions of the page's long
/// side, [strokeLength] of the edge map's diagonal and [minRegion] of the
/// page's area (from `prototypes/lineart/lineart.py`).
class _Lines {
  const _Lines(this.low, this.high, this.strokeLength, this.line, this.gap, this.minRegion, [this.rounding = 0]);

  final double low; // weakest edge kept when it continues a strong one
  final double high; // edge strength that starts a line
  final double strokeLength; // shortest line kept
  final double line; // line thickness
  final double gap; // line breaks closed for filling
  final double minRegion; // smallest fill region
  final double rounding; // cartoon rounding (cute only)

  static _Lines of(ArtStyle style, DetailLevel detail) => switch ((style, detail)) {
        (ArtStyle.cute, _) => const _Lines(0.30, 0.75, 0.070, 0.0120, 0.012, 0.0040, 0.0050),
        (_, DetailLevel.simple) => const _Lines(0.30, 0.75, 0.050, 0.0090, 0.012, 0.0040),
        (_, DetailLevel.normal) => const _Lines(0.20, 0.55, 0.025, 0.0065, 0.009, 0.0015),
        (_, DetailLevel.detailed) => const _Lines(0.12, 0.40, 0.012, 0.0045, 0.006, 0.0006),
      };
}
