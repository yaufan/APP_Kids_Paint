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

/// "Where shall we send it?" Gugu holds the postcard; the child taps one of
/// four big places (or "more places"). Pictures and voice, no reading.
class SendScreen extends ConsumerStatefulWidget {
  const SendScreen({super.key, required this.artworkId});

  final int artworkId;

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  late final Future<({Artwork artwork, List<PlaceKind> kinds, bool sentBefore})> _data = _load();
  bool _more = false;
  bool _sending = false;

  Future<({Artwork artwork, List<PlaceKind> kinds, bool sentBefore})> _load() async {
    final child = await ref.read(currentChildProvider.future);
    final repo = ref.read(artworkRepositoryProvider);
    final preferred = ref.read(preferredPlaceProvider);
    final suggested = await repo.suggestedKinds(child.id, count: 5);
    final kinds = <PlaceKind>[];
    for (final k in [?preferred, ...suggested]) {
      if (!kinds.contains(k)) kinds.add(k);
    }
    final postcards = await repo.watchPostcards(child.id).first;
    return (
      artwork: await repo.get(widget.artworkId),
      kinds: kinds.take(4).toList(),
      sentBefore: postcards.isNotEmpty || preferred != null,
    );
  }

  Future<void> _send(PlaceKind kind) async {
    if (_sending) return;
    setState(() => _sending = true);
    final child = await ref.read(currentChildProvider.future);
    final artworks = ref.read(artworkRepositoryProvider);
    final postcards = await artworks.watchPostcards(child.id).first;
    final isNew =
        kind != PlaceKind.home && !postcards.any((p) => p.place.kind == kind.name && p.artwork.id != widget.artworkId);
    final place = await ref.read(placeRepositoryProvider).defaultPlace(child.id, kind);
    await artworks.send(widget.artworkId, place.id);
    ref.read(preferredPlaceProvider.notifier).choose(null);
    if (mounted) context.go('/sent/${widget.artworkId}?kind=${kind.name}${isNew ? '&new=1' : ''}');
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(artworkStoreProvider);
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: FutureBuilder(
            future: _data,
            builder: (context, snap) {
              final data = snap.data;
              if (data == null) return const Center(child: BouncingDots());
              final picture = store.open(data.artwork.folder).thumbnail;
              final cards = _more ? PlaceKind.values : data.kinds;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 14,
                              top: 12,
                              child: NavButton(icon: 'back', label: Strings.close, onPressed: () => context.pop()),
                            ),
                            Positioned(
                              left: 30,
                              top: 70,
                              child: PostcardFrame(
                                tilt: -8,
                                padding: 7,
                                radius: 16,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(picture, width: 128, height: 118, fit: BoxFit.cover),
                                ),
                              ),
                            ),
                            const Positioned(left: 128, top: 20, child: ArtSvg(Art.pigeon, size: 126)),
                            const Positioned(right: 16, top: 150, child: VoiceBubble(Strings.whereTo, fontSize: 19)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.count(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                          crossAxisCount: _more ? 3 : 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: _more ? 0.9 : 1.05,
                          children: [
                            for (final (i, kind) in cards.indexed)
                              _PlaceCard(
                                kind: kind,
                                tag: !_more && i == 0 && data.sentBefore ? Strings.lastTime : null,
                                compact: _more,
                                onTap: _sending ? null : () => _send(kind),
                              ),
                          ],
                        ),
                      ),
                      if (!_more)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: ChunkyButton(
                            label: Strings.morePlaces,
                            onPressed: () => setState(() => _more = true),
                            width: 230,
                            height: 64,
                            depth: 5,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ArtSvg('assets/art/places/zoo.svg', size: 30),
                                ArtSvg('assets/art/places/food.svg', size: 30),
                                ArtSvg('assets/art/places/water.svg', size: 30),
                                SizedBox(width: 8),
                                Text(Strings.morePlaces, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.kind, required this.onTap, this.tag, this.compact = false});

  final PlaceKind kind;
  final VoidCallback? onTap;
  final String? tag;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final highlighted = tag != null;
    return Semantics(
      button: true,
      label: Strings.sendTo(kind.label),
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: highlighted
                ? [const BoxShadow(color: KidColors.sun, spreadRadius: 5), ...KidShadows.soft(KidColors.sunDark)]
                : const [BoxShadow(color: Color(0xFFE6DCCB), offset: Offset(0, 6))],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ArtSvg(Art.place(kind), size: compact ? 64 : 96),
                    const SizedBox(height: 4),
                    Text(
                      kind.label,
                      style: TextStyle(fontSize: compact ? 15 : 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              if (tag != null)
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: KidColors.sun, borderRadius: BorderRadius.circular(14)),
                    child: Text(tag!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
