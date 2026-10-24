import 'package:flutter/widgets.dart';

/// 3D illustrations from Microsoft Fluent Emoji (MIT license), bundled in
/// `assets/illustrations/`. Placeholders for the app's own art later.
abstract final class Art {
  static const _dir = 'assets/illustrations';

  static const camera = '$_dir/camera.png';
  static const gallery = '$_dir/gallery.png';
  static const map = '$_dir/map.png';
  static const home = '$_dir/home.png';
  static const crayon = '$_dir/crayon.png';
  static const bucket = '$_dir/bucket.png';
  static const brush = '$_dir/brush.png';
  static const undo = '$_dir/undo.png';
  static const heart = '$_dir/heart.png';
  static const heartEmpty = '$_dir/heart_empty.png';
  static const sparkles = '$_dir/sparkles.png';
  static const party = '$_dir/party.png';
  static const star = '$_dir/star.png';
  static const palette = '$_dir/palette.png';
  static const sun = '$_dir/sun.png';
  static const cloud = '$_dir/cloud.png';
  static const rainbow = '$_dir/rainbow.png';
  static const tree = '$_dir/tree.png';
  static const tulip = '$_dir/tulip.png';
  static const blossom = '$_dir/blossom.png';
  static const sunflower = '$_dir/sunflower.png';

  static const _avatars = {
    '🐻': 'avatar_bear',
    '🐰': 'avatar_rabbit',
    '🐱': 'avatar_cat',
    '🐶': 'avatar_dog',
    '🐼': 'avatar_panda',
    '🦊': 'avatar_fox',
    '🐸': 'avatar_frog',
    '🐧': 'avatar_penguin',
  };

  /// The 3D picture for a child's avatar (stored as an emoji).
  static String avatar(String emoji) => '$_dir/${_avatars[emoji] ?? 'avatar_bear'}.png';
}

/// A bundled illustration, smoothly scaled.
class ArtImage extends StatelessWidget {
  const ArtImage(this.asset, {super.key, this.size});

  final String asset;
  final double? size;

  @override
  Widget build(BuildContext context) => Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        excludeFromSemantics: true,
      );
}
