import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/creatures.dart';
import '../core/festivals.dart';
import '../core/places.dart';
import '../core/town_time.dart';

/// The app's drawings (design v3), all vector art made for this app in
/// docs/design/v3/src and exported with `export_art.py`.
abstract final class Art {
  static const _dir = 'assets/art';

  static String icon(String name, {bool solid = false}) => '$_dir/icons/$name${solid ? '_solid' : ''}.svg';
  static String place(PlaceKind kind) => '$_dir/places/${kind.name}.svg';
  static String animal(String kind) => '$_dir/animals/${animals.contains(kind) ? kind : animals.first}.svg';
  static String town(String layer, DayPhase phase) => '$_dir/town/${layer}_${phase.name}.svg';
  static String festival(Festival f) => '$_dir/festivals/${f.name}.svg';

  /// A built-in coloring page (a festival's, a creature's): black lines on white.
  static String page(String name) => 'assets/pages/$name.png';

  /// A place you go into, painted (docs/design/v4/draw_scenes.py).
  static String scene(Habitat h) => 'assets/scenes/${h.name}.jpg';

  static const pigeon = '$_dir/pigeon.svg';
  static const pigeonFlying = '$_dir/pigeon_flying.svg';
  static const pigeonFlyingLetter = '$_dir/pigeon_flying_letter.svg';
  static const pigeonAsleep = '$_dir/pigeon_asleep.svg';
  static const logo = '$_dir/logo.svg';
  static const miniAlbum = '$_dir/ui/mini_album.svg';
  static const miniBook = '$_dir/ui/mini_book.svg';
  static const miniPaper = '$_dir/ui/mini_paper.svg';
  static const bucket = '$_dir/tools/bucket.svg';
  static const crayon = '$_dir/tools/crayon.svg';
  static const rainbow = '$_dir/tools/rainbow.svg';
  static const glitter = '$_dir/tools/glitter.svg';
  static const stamp = '$_dir/tools/stamp.svg';
  static const eraser = '$_dir/tools/eraser.svg';
  static String stampShape(String name) => '$_dir/stamps/$name.svg';
}

/// A drawing at a fixed size. Decorative: screen readers skip it.
class ArtSvg extends StatelessWidget {
  const ArtSvg(this.asset, {super.key, this.size, this.width, this.height});

  final String asset;
  final double? size;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SvgPicture.asset(asset, width: width ?? size, height: height ?? size),
      );
}

/// A line icon in any color.
class KidIcon extends StatelessWidget {
  const KidIcon(this.name, {super.key, this.size = 28, this.color = const Color(0xFF34413A), this.solid = false});

  final String name;
  final double size;
  final Color color;
  final bool solid;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SvgPicture.asset(
          Art.icon(name, solid: solid),
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      );
}

/// The child's animal.
class AnimalArt extends StatelessWidget {
  const AnimalArt(this.kind, {super.key, this.size = 56});

  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) => ArtSvg(Art.animal(kind), size: size);
}

/// A tool drawn in the chosen color (the bucket's paint, the crayon's wax).
class ToolArt extends StatelessWidget {
  const ToolArt(this.asset, {super.key, required this.color, this.size = 40});

  final String asset;
  final Color color;
  final double size;

  /// Loaded templates; kept as text (not futures) so a test's zone never
  /// leaks into the next one.
  static final _templates = <String, String>{};

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static Color _shade(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final cached = _templates[asset];
    final template = cached != null
        ? Future.value(cached)
        : rootBundle.loadString(asset).then((svg) => _templates[asset] = svg);
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size * 1.2,
        child: FutureBuilder<String>(
          initialData: cached,
          future: template,
          builder: (context, snap) {
            final svg = snap.data;
            if (svg == null) return const SizedBox.shrink();
            // White paint would vanish on the white bucket: give it an edge.
            final dark = color.computeLuminance() > 0.9 ? const Color(0xFFB9C2CC) : _shade(color, -0.25);
            return SvgPicture.string(
              svg
                  .replaceAll('#C0FFEE', _hex(color))
                  .replaceAll('#C0FFE1', _hex(dark))
                  .replaceAll('#C0FFE2', _hex(_shade(color, 0.15))),
              width: size,
              height: size * 1.2,
            );
          },
        ),
      ),
    );
  }
}
