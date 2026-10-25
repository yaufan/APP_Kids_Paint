import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/db/database.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import '../../core/repositories.dart';

/// All the child's postcards, grouped by where they were sent, plus the
/// pictures that are not sent yet. Hearts mark favorites.
class AlbumScreen extends ConsumerStatefulWidget {
  const AlbumScreen({super.key});

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  /// null: everything; otherwise only this kind of place.
  PlaceKind? _kind;
  bool _favorites = false;

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(currentChildProvider).value;
    final postcards = child == null ? const <Postcard>[] : ref.watch(postcardsProvider(child.id)).value ?? const [];
    final all = child == null
        ? const <Artwork>[]
        : ref.watch(artworksProvider((childId: child.id, favoritesOnly: false))).value ?? const [];
    final drafts = [for (final a in all) if (a.sentAt == null) a];

    final kinds = <PlaceKind>[];
    for (final p in postcards) {
      final k = PlaceKind.byName(p.place.kind);
      if (!kinds.contains(k)) kinds.add(k);
    }
    final shown = [
      for (final p in postcards)
        if ((_kind == null || p.place.kind == _kind!.name) && (!_favorites || p.artwork.isFavorite)) p,
    ];
    final groups = <Place, List<Postcard>>{};
    for (final p in shown) {
      groups.putIfAbsent(groups.keys.firstWhere((k) => k.id == p.place.id, orElse: () => p.place), () => []).add(p);
    }

    Widget chip(String text, {required bool selected, required VoidCallback onTap, Widget? leading, int? count}) => Semantics(
          button: true,
          selected: selected,
          label: text,
          excludeSemantics: true,
          child: Pressable(
            onTap: onTap,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? KidColors.coral : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: selected ? KidColors.coralDark : const Color(0xFFE8DCC8), offset: const Offset(0, 3))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (leading != null) ...[leading, const SizedBox(width: 6)],
                Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: selected ? Colors.white : KidColors.ink)),
                if (count != null) ...[
                  const SizedBox(width: 6),
                  Text('$count', style: TextStyle(fontSize: 15, color: selected ? Colors.white70 : KidColors.inkSoft)),
                ],
              ]),
            ),
          ),
        );

    final store = ref.watch(artworkStoreProvider);
    final width = MediaQuery.sizeOf(context).width;
    final columns = (width / 190).floor().clamp(2, 6);

    Widget grid(List<Artwork> arts, {required bool sent}) => GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
          childAspectRatio: 166 / 190,
          children: [
            for (final (i, art) in arts.indexed)
              _AlbumCard(
                artwork: art,
                image: FileImage(store.open(art.folder).thumbnail),
                tilt: i.isEven ? -1.5 : 1.5,
                sent: sent,
                onOpen: () => context.push('/canvas/${art.id}'),
                onFavorite: () => ref.read(artworkRepositoryProvider).toggleFavorite(art.id),
              ),
          ],
        );

    Widget header(Widget icon, String title, int n) => Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
          child: Row(children: [
            icon,
            const SizedBox(width: 8),
            Flexible(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text(Strings.count(n), style: const TextStyle(fontSize: 15, color: KidColors.inkSoft)),
          ]),
        );

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(children: [
                NavButton(icon: 'map', label: Strings.backToMap, color: KidColors.grassDark, onPressed: () => context.go('/')),
                const Spacer(),
                const ArtSvg(Art.miniAlbum, size: 40),
                const SizedBox(width: 8),
                const Text(Strings.album, style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
                const Spacer(),
                const SizedBox(width: KidTheme.navButton),
              ]),
            ),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                children: [
                  chip(Strings.all, selected: _kind == null && !_favorites, count: postcards.length, onTap: () => setState(() {
                        _kind = null;
                        _favorites = false;
                      })),
                  const SizedBox(width: 10),
                  chip(Strings.favorites,
                      selected: _favorites,
                      leading: const KidIcon('heart', size: 16, color: Color(0xFFFF6F91), solid: true),
                      onTap: () => setState(() => _favorites = !_favorites)),
                  for (final k in kinds) ...[
                    const SizedBox(width: 10),
                    chip(k.label,
                        selected: _kind == k,
                        count: postcards.where((p) => p.place.kind == k.name).length,
                        onTap: () => setState(() => _kind = _kind == k ? null : k)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: postcards.isEmpty && drafts.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        AnimalArt(child?.avatar ?? animals.first, size: 120),
                        const SizedBox(height: 16),
                        const VoiceBubble(Strings.emptyAlbum),
                        const SizedBox(height: 24),
                        ChunkyButton(
                          label: Strings.takePhoto,
                          onPressed: () => context.push('/capture'),
                          circle: true,
                          width: 104,
                          height: 104,
                          color: KidColors.coral,
                          edge: KidColors.coralDark,
                          child: const KidIcon('camera', size: 48, color: Colors.white),
                        ),
                      ]),
                    )
                  : ListView(padding: const EdgeInsets.only(bottom: 30), children: [
                      for (final MapEntry(key: place, value: items) in groups.entries) ...[
                        header(ArtSvg(Art.place(PlaceKind.byName(place.kind)), size: 30), place.label ?? PlaceKind.byName(place.kind).label, items.length),
                        grid([for (final p in items) p.artwork], sent: true),
                      ],
                      if (drafts.isNotEmpty && _kind == null && !_favorites) ...[
                        header(const KidIcon('crayon', size: 26, color: KidColors.inkSoft), Strings.drafts, drafts.length),
                        grid(drafts, sent: false),
                      ],
                    ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({
    required this.artwork,
    required this.image,
    required this.tilt,
    required this.sent,
    required this.onOpen,
    required this.onFavorite,
  });

  final Artwork artwork;
  final ImageProvider image;
  final double tilt;
  final bool sent;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final date = shortDate(artwork.sentAt ?? artwork.updatedAt);
    return Semantics(
      button: true,
      label: '$date 的明信片',
      child: Pressable(
        onTap: onOpen,
        child: PostcardFrame(
          tilt: tilt,
          padding: 8,
          radius: 18,
          child: Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.expand(child: Image(image: image, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => const ColoredBox(color: Colors.white))),
              ),
            ),
            SizedBox(
              height: 34,
              child: Row(children: [
                const SizedBox(width: 4),
                Text(date, style: const TextStyle(fontSize: 15, color: KidColors.inkSoft)),
                const Spacer(),
                if (sent)
                  Semantics(
                    button: true,
                    selected: artwork.isFavorite,
                    label: Strings.favorite,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onFavorite,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: KidIcon('heart', size: 24, color: artwork.isFavorite ? const Color(0xFFFF6F91) : const Color(0xFFC9BBA6), solid: artwork.isFavorite),
                      ),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
