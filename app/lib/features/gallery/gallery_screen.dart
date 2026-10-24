import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/mascot.dart';
import '../../app/scene.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';

/// A wall of the child's pictures, newest first, each a taped-up photo;
/// hearts mark favorites.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  bool _favoritesOnly = false;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(currentChildProvider).value;
    final artworks = child == null
        ? const AsyncValue<List<Artwork>>.loading()
        : ref.watch(artworksProvider((childId: child.id, favoritesOnly: _favoritesOnly)));

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    HomeButton(onPressed: () => context.go('/')),
                    const Spacer(),
                    KidButton(
                      icon: _favoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      label: Strings.favorite,
                      color: KidColors.berry,
                      size: KidTheme.toolButton,
                      selected: _favoritesOnly,
                      onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: artworks.when(
                  loading: () => const Center(child: BouncingDots()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (list) => list.isEmpty
                      ? _EmptyWall(favoritesOnly: _favoritesOnly)
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            mainAxisSpacing: 36,
                            crossAxisSpacing: 28,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, i) => _ArtworkTile(artwork: list[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nothing here yet: the mascot points the way to the camera.
class _EmptyWall extends StatelessWidget {
  const _EmptyWall({required this.favoritesOnly});

  final bool favoritesOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CrayonBuddy(height: 170, color: KidColors.sky),
          const SizedBox(height: 28),
          if (!favoritesOnly)
            KidButton(
              icon: Icons.photo_camera_rounded,
              label: Strings.takePhoto,
              color: KidColors.berry,
              breathing: true,
              onPressed: () => context.go('/capture'),
            ),
        ],
      ),
    );
  }
}

class _ArtworkTile extends ConsumerWidget {
  const _ArtworkTile({required this.artwork});

  final Artwork artwork;

  static const _tapes = [KidColors.sun, KidColors.sky, KidColors.berry, KidColors.grass, KidColors.lavender];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(artworkStoreProvider).open(artwork.folder);
    final preview = files.thumbnail.existsSync() ? files.thumbnail : files.lines;
    // A fixed, slightly different tilt per picture, like photos taped to a wall.
    final tilt = ((artwork.id * 37) % 7 - 3) * 0.9;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => context.push('/canvas/${artwork.id}'),
            child: StickerCard(
              tilt: tilt,
              tape: _tapes[artwork.id % _tapes.length],
              padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
              child: Center(child: Image.file(preview, fit: BoxFit.contain)),
            ),
          ),
        ),
        Positioned(
          right: -10,
          bottom: -10,
          child: KidButton(
            icon: artwork.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: Strings.favorite,
            color: artwork.isFavorite ? KidColors.berry : Colors.white,
            iconColor: artwork.isFavorite ? Colors.white : KidColors.berry,
            size: 54,
            onPressed: () => ref.read(artworkRepositoryProvider).toggleFavorite(artwork.id),
          ),
        ),
      ],
    );
  }
}
