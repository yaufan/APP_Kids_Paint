import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../lineart/region_map.dart';

/// Bright, toddler-friendly colors (ARGB). Twelve big paint pots, no color wheel.
const kidPalette = <int>[
  0xFFFF5E5B, // red
  0xFFFF9F45, // orange
  0xFFFFD166, // yellow
  0xFF5FCB79, // green
  0xFF2EC4B6, // teal
  0xFF4DA3FF, // blue
  0xFF8C6CFF, // purple
  0xFFFF8FB1, // pink
  0xFFA0673F, // brown
  0xFFFFD2B8, // skin peach
  0xFFFFFFFF, // white (works as an eraser)
  0xFF34413A, // dark green-black
];

/// What each color is called, for screen readers.
const kidPaletteNames = ['紅', '橘', '黃', '綠', '藍綠', '藍', '紫', '粉紅', '咖啡', '膚', '白', '黑'];

/// One thing the child did. The page is always rebuilt from this list, which
/// gives undo, autosave and a time-lapse replay for free.
sealed class PaintOp {
  const PaintOp(this.color);

  final int color;

  Map<String, Object> toJson();

  static PaintOp fromJson(Map<String, dynamic> json) => switch (json['type']) {
        'fill' => FillOp(json['region'] as int, json['color'] as int),
        'crayon' => CrayonOp(
            json['region'] as int,
            json['color'] as int,
            (json['radius'] as num).toDouble(),
            [for (final p in json['points'] as List) (x: (p[0] as num).toDouble(), y: (p[1] as num).toDouble())],
            brush: Brush.values.byName(json['brush'] as String? ?? 'crayon'),
          ),
        'stamp' => StampOp(
            json['region'] as int,
            json['color'] as int,
            StampShape.values.byName(json['shape'] as String),
            (json['x'] as num).toDouble(),
            (json['y'] as num).toDouble(),
            (json['radius'] as num).toDouble(),
          ),
        'paper' => PaperOp(json['color'] as int),
        _ => throw FormatException('unknown paint op ${json['type']}'),
      };
}

/// Bucket fill: one tap colors a whole region.
class FillOp extends PaintOp {
  const FillOp(this.region, int color) : super(color);

  final int region;

  @override
  Map<String, Object> toJson() => {'type': 'fill', 'region': region, 'color': color};
}

/// The stamps a child can press onto the page.
enum StampShape { star, heart, flower, paw }

/// A stamp pressed at ([x], [y]), as big as [radius], kept inside the
/// region it was pressed in.
class StampOp extends PaintOp {
  const StampOp(this.region, super.color, this.shape, this.x, this.y, this.radius);

  final int region;
  final StampShape shape;
  final double x;
  final double y;
  final double radius;

  @override
  Map<String, Object> toJson() => {
        'type': 'stamp',
        'region': region,
        'color': color,
        'shape': shape.name,
        'x': double.parse(x.toStringAsFixed(1)),
        'y': double.parse(y.toStringAsFixed(1)),
        'radius': double.parse(radius.toStringAsFixed(1)),
      };
}

/// Whether a stamp covers the point ([u], [v]) of its square, -1..1 each
/// way with v pointing down. Matches assets/art/stamps/.
bool stampContains(StampShape shape, double u, double v) {
  bool circle(double cx, double cy, double r) => (u - cx) * (u - cx) + (v - cy) * (v - cy) <= r * r;
  switch (shape) {
    case StampShape.star:
      // A five-pointed star: inside the polygon of its ten corners.
      var inside = false;
      for (var k = 0, j = 9; k < 10; j = k++) {
        final rk = k.isEven ? 1.0 : 0.45, rj = j.isEven ? 1.0 : 0.45;
        final xk = rk * math.sin(k * math.pi / 5), yk = -rk * math.cos(k * math.pi / 5);
        final xj = rj * math.sin(j * math.pi / 5), yj = -rj * math.cos(j * math.pi / 5);
        if ((yk > v) != (yj > v) && u < (xj - xk) * (v - yk) / (yj - yk) + xk) inside = !inside;
      }
      return inside;
    case StampShape.heart:
      final x = u * 1.25, y = -v * 1.25 + 0.25;
      final a = x * x + y * y - 1;
      return a * a * a - x * x * y * y * y <= 0;
    case StampShape.flower:
      if (circle(0, 0, 0.4)) return true;
      for (var k = 0; k < 5; k++) {
        if (circle(0.55 * math.sin(k * 2 * math.pi / 5), -0.55 * math.cos(k * 2 * math.pi / 5), 0.42)) return true;
      }
      return false;
    case StampShape.paw:
      final pad = (u * u) / (0.55 * 0.55) + (v - 0.35) * (v - 0.35) / (0.45 * 0.45) <= 1;
      return pad || circle(-0.62, -0.2, 0.22) || circle(-0.24, -0.6, 0.24) || circle(0.24, -0.6, 0.24) || circle(0.62, -0.2, 0.22);
  }
}

/// Blank paper's bucket: the paper itself changes color, behind everything
/// already drawn on it.
class PaperOp extends PaintOp {
  const PaperOp(super.color);

  @override
  Map<String, Object> toJson() => {'type': 'paper', 'color': color};
}

typedef PagePoint = ({double x, double y});

/// What a stroke is drawn with.
enum Brush {
  /// The chosen color.
  crayon,

  /// Every color of the rainbow, one after another along the stroke.
  rainbow,

  /// The chosen color with sparkles in it.
  glitter,

  /// Back to the paper.
  eraser,
}

/// Magic crayon (and the other brushes): a stroke that only colors the
/// region it started in.
class CrayonOp extends PaintOp {
  CrayonOp(this.region, int color, this.radius, this.points, {this.brush = Brush.crayon}) : super(color);

  final int region;
  final double radius;
  final List<PagePoint> points;
  final Brush brush;

  @override
  Map<String, Object> toJson() => {
        'type': 'crayon',
        if (brush != Brush.crayon) 'brush': brush.name,
        'region': region,
        'color': color,
        'radius': radius,
        'points': [
          for (final p in points) [double.parse(p.x.toStringAsFixed(1)), double.parse(p.y.toStringAsFixed(1))]
        ],
      };
}

/// The color layer of a page, kept as RGBA pixels under the line art.
class ColoringDocument {
  ColoringDocument(this.regions, [List<PaintOp>? ops])
      : ops = ops ?? [],
        rgba = Uint8List(regions.width * regions.height * 4) {
    rebuild();
  }

  final RegionMap regions;
  final List<PaintOp> ops;
  final Uint8List rgba;

  /// The paper's color as of the last rebuild (what the eraser brings back).
  int _paper = 0xFFFFFFFF;

  int get width => regions.width;
  int get height => regions.height;
  bool get canUndo => ops.isNotEmpty;

  /// Bucket fill at a page position; returns false when nothing is there.
  bool fill(double x, double y, int color) {
    final region = regions.labelAt(x.floor(), y.floor());
    if (region == 0) return false;
    add(FillOp(region, color));
    return true;
  }

  void add(PaintOp op) {
    ops.add(op);
    if (op is PaperOp) {
      rebuild();
    } else {
      _apply(op);
    }
  }

  /// The paper's color: white unless blank paper was recolored.
  int get paper => ops.whereType<PaperOp>().lastOrNull?.color ?? 0xFFFFFFFF;

  void undo() {
    if (ops.isEmpty) return;
    ops.removeLast();
    rebuild();
  }

  void rebuild() {
    final paper = _paper = this.paper;
    for (var i = 0; i < rgba.length ~/ 4; i++) {
      _set(i, paper);
    }
    for (final op in ops) {
      _apply(op);
    }
  }

  /// ARGB color at a pixel of the color layer (for tests and previews).
  int colorAt(int x, int y) {
    final i = (y * width + x) * 4;
    return (rgba[i + 3] << 24) | (rgba[i] << 16) | (rgba[i + 1] << 8) | rgba[i + 2];
  }

  void _apply(PaintOp op) {
    switch (op) {
      case FillOp(:final region, :final color):
        final labels = regions.labels;
        for (var i = 0; i < labels.length; i++) {
          if (labels[i] == region) _set(i, color);
        }
      case CrayonOp():
        applyStroke(op, 0);
      case StampOp():
        _stamp(op);
      case PaperOp():
        break; // drawn first, by rebuild()
    }
  }

  /// Paints the part of a crayon stroke from point [from] on; the canvas
  /// calls this while the finger moves so the stroke shows up live.
  void applyStroke(CrayonOp op, int from) {
    final pts = op.points;
    if (pts.isEmpty) return;
    double dist(PagePoint a, PagePoint b) => math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
    final start = math.max(0, from - 1);
    // How far along the stroke we are: the rainbow's color depends on it.
    var travelled = 0.0;
    for (var k = 1; k <= start; k++) {
      travelled += dist(pts[k - 1], pts[k]);
    }
    _dab(op, pts[start], travelled);
    for (var k = start + 1; k < pts.length; k++) {
      final a = pts[k - 1], b = pts[k];
      final d = dist(a, b);
      final steps = math.max(1, (d / (op.radius * 0.4)).ceil());
      for (var s = 1; s <= steps; s++) {
        final t = s / steps;
        _dab(op, (x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t), travelled + d * t);
      }
      travelled += d;
    }
  }

  void _dab(CrayonOp op, PagePoint c, double travelled) {
    final color = switch (op.brush) {
      Brush.rainbow => rainbowColor(travelled / (op.radius * 6)),
      Brush.eraser => _paper,
      Brush.crayon || Brush.glitter => op.color,
    };
    final glitter = op.brush == Brush.glitter;
    final r = op.radius, r2 = r * r;
    final x0 = math.max(0, (c.x - r).floor()), x1 = math.min(width - 1, (c.x + r).ceil());
    final y0 = math.max(0, (c.y - r).floor()), y1 = math.min(height - 1, (c.y + r).ceil());
    final labels = regions.labels;
    for (var y = y0; y <= y1; y++) {
      final dy = y - c.y;
      for (var x = x0; x <= x1; x++) {
        final dx = x - c.x;
        if (dx * dx + dy * dy > r2) continue;
        final i = y * width + x;
        if (labels[i] == op.region) _set(i, glitter ? sparkle(x, y, color) : color);
      }
    }
  }

  void _stamp(StampOp op) {
    final r = op.radius;
    final x0 = math.max(0, (op.x - r).floor()), x1 = math.min(width - 1, (op.x + r).ceil());
    final y0 = math.max(0, (op.y - r).floor()), y1 = math.min(height - 1, (op.y + r).ceil());
    final labels = regions.labels;
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final i = y * width + x;
        if (labels[i] == op.region && stampContains(op.shape, (x - op.x) / r, (y - op.y) / r)) _set(i, op.color);
      }
    }
  }

  void _set(int i, int argb) {
    final o = i * 4;
    rgba[o] = (argb >> 16) & 0xFF;
    rgba[o + 1] = (argb >> 8) & 0xFF;
    rgba[o + 2] = argb & 0xFF;
    rgba[o + 3] = 0xFF;
  }

  String encodeOps() => jsonEncode({'version': 1, 'ops': [for (final op in ops) op.toJson()]});

  static List<PaintOp> decodeOps(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return [for (final op in json['ops'] as List) PaintOp.fromJson(op as Map<String, dynamic>)];
  }
}

/// The rainbow at [t] (any number; one color per unit, cycling).
int rainbowColor(double t) {
  final hue = (t * 40) % 360;
  final c = 0.75, x = c * (1 - ((hue / 60) % 2 - 1).abs()), m = 1 - c;
  final (r, g, b) = switch (hue ~/ 60) {
    0 => (c, x, 0.0),
    1 => (x, c, 0.0),
    2 => (0.0, c, x),
    3 => (0.0, x, c),
    4 => (x, 0.0, c),
    _ => (c, 0.0, x),
  };
  int channel(double v) => ((v + m) * 255).round();
  return 0xFF000000 | channel(r) << 16 | channel(g) << 8 | channel(b);
}

/// Glitter: the color, with little white, pale and gold flecks scattered
/// over the page in fixed places (so redrawing gives the same sparkles).
int sparkle(int x, int y, int color) {
  final cell = ((x ~/ 5) * 73856093 ^ (y ~/ 5) * 19349663) & 0x7fffffff;
  final n = cell % 100;
  if (n < 7) return 0xFFFFFFFF;
  if (n < 12) return 0xFFFFE27A;
  if (n < 20) {
    final r = (color >> 16) & 0xFF, g = (color >> 8) & 0xFF, b = color & 0xFF;
    return 0xFF000000 | ((r + 255) ~/ 2) << 16 | ((g + 255) ~/ 2) << 8 | ((b + 255) ~/ 2);
  }
  return color;
}
