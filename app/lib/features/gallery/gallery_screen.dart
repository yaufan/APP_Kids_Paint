import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';

/// A big wall of the child's pictures, newest first; hearts mark favorites.
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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  KidButton(
                    icon: Icons.home_rounded,
                    label: Strings.home,
                    color: KidTheme.sun,
                    size: KidTheme.toolButton,
                    onPressed: () => context.go('/'),
                  ),
                  const Spacer(),
                  KidButton(
                    icon: Icons.favorite_rounded,
                    label: Strings.favorite,
                    color: KidTheme.berry,
                    size: KidTheme.toolButton,
                    selected: _favoritesOnly,
                    onPressed: () => setState(() => _favoritesOnly = !_favoritesOnly),
                  ),
                ],
              ),
            ),
            Expanded(
              child: artworks.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (list) => GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _ArtworkTile(artwork: list[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkTile extends ConsumerWidget {
  const _ArtworkTile({required this.artwork});

  final Artwork artwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final files = ref.watch(artworkStoreProvider).open(artwork.folder);
    final preview = files.thumbnail.existsSync() ? files.thumbnail : files.lines;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      child: InkWell(
        onTap: () => context.push('/canvas/${artwork.id}'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(padding: const EdgeInsets.all(8), child: Image.file(preview, fit: BoxFit.contain)),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                iconSize: 40,
                tooltip: Strings.favorite,
                onPressed: () => ref.read(artworkRepositoryProvider).toggleFavorite(artwork.id),
                icon: Icon(
                  artwork.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: KidTheme.berry,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
