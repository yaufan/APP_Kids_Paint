import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/db/database.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import '../../core/repositories.dart';

/// Tapping a pin: the postcards sent to that place, and "draw here again".
class PlaceSheet extends ConsumerWidget {
  const PlaceSheet({super.key, required this.kind, required this.postcards, required this.onDrawHere, required this.onOpen});

  final PlaceKind kind;
  final List<Postcard> postcards;
  final VoidCallback onDrawHere;
  final ValueChanged<Artwork> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(artworkStoreProvider);
    final names = {for (final p in postcards) if (p.place.label != null) p.place.label!};
    final latest = postcards.isEmpty ? null : postcards.first.artwork.sentAt;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(width: 40, height: 5, decoration: BoxDecoration(color: const Color(0xFFE3D5BE), borderRadius: BorderRadius.circular(3))),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: const Color(0xFFDDF3D6), borderRadius: BorderRadius.circular(20)),
              child: ArtSvg(Art.place(kind), size: 50),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(names.isEmpty ? kind.label : names.join('、'),
                    style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                // Two lines on a narrow phone.
                Wrap(spacing: 10, runSpacing: 2, children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const KidIcon('mail', size: 16, color: KidColors.inkSoft),
                    const SizedBox(width: 4),
                    Text(Strings.postcardsHere(postcards.length), style: const TextStyle(fontSize: 15, color: KidColors.inkSoft)),
                  ]),
                  if (latest != null)
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      const KidIcon('clock', size: 16, color: KidColors.inkSoft),
                      const SizedBox(width: 4),
                      Text(Strings.latest(shortDate(latest)), style: const TextStyle(fontSize: 15, color: KidColors.inkSoft)),
                    ]),
                ]),
              ]),
            ),
            Semantics(
              button: true,
              label: Strings.close,
              excludeSemantics: true,
              child: Pressable(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Color(0xFFF1E6D3), shape: BoxShape.circle),
                  child: const KidIcon('close', size: 20, color: KidColors.inkSoft),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: postcards.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final art = postcards[i].artwork;
                return Semantics(
                  button: true,
                  label: '${shortDate(art.sentAt ?? art.updatedAt)} 的明信片',
                  excludeSemantics: true,
                  child: Pressable(
                    onTap: () => onOpen(art),
                    child: PostcardFrame(
                      tilt: i.isEven ? -3 : 2,
                      padding: 7,
                      radius: 16,
                      child: SizedBox(
                        width: 122,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(store.open(art.folder).thumbnail, width: 122, height: 112, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 6),
                          Text(shortDate(art.sentAt ?? art.updatedAt), style: const TextStyle(fontSize: 15, color: KidColors.inkSoft)),
                        ]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          ChunkyButton(
            label: Strings.drawHere,
            onPressed: onDrawHere,
            color: KidColors.coral,
            edge: KidColors.coralDark,
            height: 76,
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              KidIcon('camera', size: 34, color: Colors.white),
              SizedBox(width: 12),
              Text(Strings.drawHere, style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
      ),
    );
  }
}
