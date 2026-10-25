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

/// Blank paper's bucket: the paper itself changes color, behind everything
/// already drawn on it.
class PaperOp extends PaintOp {
  const PaperOp(super.color);

  @override
  Map<String, Object> toJson() => {'type': 'paper', 'color': color};
}

typedef PagePoint = ({double x, double y});

/// Magic crayon: a stroke that only colors the region it started in.
class CrayonOp extends PaintOp {
  CrayonOp(this.region, int color, this.radius, this.points) : super(color);

  final int region;
  final double radius;
  final List<PagePoint> points;

  @override
  Map<String, Object> toJson() => {
        'type': 'crayon',
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
    final paper = this.paper;
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
      case PaperOp():
        break; // drawn first, by rebuild()
    }
  }

  /// Paints the part of a crayon stroke from point [from] on; the canvas
  /// calls this while the finger moves so the stroke shows up live.
  void applyStroke(CrayonOp op, int from) {
    final pts = op.points;
    if (pts.isEmpty) return;
    final start = math.max(0, from - 1);
    _dab(op, pts[start]);
    for (var k = start + 1; k < pts.length; k++) {
      final a = pts[k - 1], b = pts[k];
      final dist = math.sqrt(math.pow(b.x - a.x, 2) + math.pow(b.y - a.y, 2));
      final steps = math.max(1, (dist / (op.radius * 0.4)).ceil());
      for (var s = 1; s <= steps; s++) {
        final t = s / steps;
        _dab(op, (x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t));
      }
    }
  }

  void _dab(CrayonOp op, PagePoint c) {
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
        if (labels[i] == op.region) _set(i, op.color);
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
