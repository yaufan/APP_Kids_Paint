import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/art.dart';
import '../../app/widgets.dart';
import '../../core/db/database.dart';
import '../../core/festivals.dart';
import '../../core/places.dart';
import '../../core/providers.dart';

/// The stamp on a postcard: the original photo, the festival's picture for a
/// festival page, or the child's animal on blank paper.
class ArtworkStamp extends ConsumerWidget {
  const ArtworkStamp({super.key, required this.artwork, this.width = 76, this.height = 90});

  final Artwork artwork;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final art = width * 0.7;
    final festival = Festival.byName(artwork.template);
    if (festival != null) {
      return PhotoStamp(width: width, height: height, child: ArtSvg(Art.festival(festival), size: art));
    }
    if (artwork.style == 'blank') {
      final avatar = ref.watch(currentChildProvider).value?.avatar ?? animals.first;
      return PhotoStamp(width: width, height: height, child: AnimalArt(avatar, size: art));
    }
    return PhotoStamp(width: width, height: height, image: FileImage(ref.watch(artworkStoreProvider).open(artwork.folder).photo));
  }
}
