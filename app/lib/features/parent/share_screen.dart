import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/creatures.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import '../../core/repositories.dart';

/// How a shared card says where the postcard went.
enum SharedPlace {
  /// Just the kind of place: 「公園」.
  kind,

  /// The name a parent gave it: 「大安森林公園」.
  name,

  /// Not at all.
  none,
}

/// Parent mode: share a postcard (0.17). A card is made for it: the
/// picture in a postcard frame, the date, the child's animal saying a word
/// and the app's name. Never the photo it came from, never the child's
/// name; where it went only as the parent chooses (docs/safety-privacy.md §5).
class ShareScreen extends ConsumerStatefulWidget {
  const ShareScreen({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  Postcard? _chosen;
  SharedPlace _place = SharedPlace.kind;
  final _card = GlobalKey();
  final _button = GlobalKey();
  bool _sharing = false;

  Future<void> _share(Postcard postcard) async {
    final boundary = _card.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      final picture = FileImage(ref.read(artworkStoreProvider).open(postcard.artwork.folder).colored);
      await precacheImage(picture, context);
      // A frame with the picture drawn, then the card at about 1080 px across.
      await WidgetsBinding.instance.endOfFrame;
      final image = await boundary.toImage(pixelRatio: 1080 / boundary.size.width);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final box = _button.currentContext?.findRenderObject() as RenderBox?;
      final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      final sent = postcard.artwork.sentAt ?? postcard.artwork.updatedAt;
      await ref.read(sharerProvider).shareImage(
            data!.buffer.asUint8List(),
            name: '畫畫小鎮-${sent.year}${_two(sent.month)}${_two(sent.day)}.png',
            origin: origin,
          );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.shareFailed)));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(currentChildProvider).value;
    final postcards = child == null ? const <Postcard>[] : ref.watch(postcardsProvider(child.id)).value ?? const [];
    final store = ref.watch(artworkStoreProvider);
    final chosen = _chosen;

    return Scaffold(
      backgroundColor: KidColors.parentBg,
      appBar: AppBar(
        backgroundColor: KidColors.parentBg,
        title: const Text(Strings.shareArt, style: TextStyle(fontWeight: FontWeight.w700)),
        leading: chosen == null ? null : BackButton(onPressed: () => setState(() => _chosen = null)),
      ),
      body: chosen == null
          ? postcards.isEmpty
              ? const Center(child: Text(Strings.nothingToShare, style: TextStyle(fontSize: 16, color: KidColors.inkSoft)))
              : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
                  const Text(Strings.pickToShare, style: TextStyle(fontSize: 15, color: KidColors.inkSoft)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: (MediaQuery.sizeOf(context).width / 150).floor().clamp(2, 6),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      for (final p in postcards)
                        Semantics(
                          button: true,
                          label: shortDate(p.artwork.sentAt ?? p.artwork.updatedAt),
                          child: InkWell(
                            key: ValueKey('share-pick-${p.artwork.id}'),
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() {
                              _chosen = p;
                              _place = SharedPlace.kind;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image(image: FileImage(store.open(p.artwork.folder).thumbnail), fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const ColoredBox(color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ])
          : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: RepaintBoundary(
                    key: _card,
                    child: ShareCard(
                      postcard: chosen,
                      picture: FileImage(store.open(chosen.artwork.folder).colored),
                      avatar: child?.avatar ?? animals.first,
                      place: _place,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(Strings.sharedPlaceTitle, style: TextStyle(fontSize: 14, color: KidColors.inkSoft)),
              const SizedBox(height: 8),
              SegmentedButton<SharedPlace>(
                showSelectedIcon: false,
                segments: [
                  const ButtonSegment(value: SharedPlace.kind, label: Text(Strings.sharedPlaceKind)),
                  if (chosen.place.label != null) const ButtonSegment(value: SharedPlace.name, label: Text(Strings.sharedPlaceName)),
                  const ButtonSegment(value: SharedPlace.none, label: Text(Strings.sharedPlaceNone)),
                ],
                selected: {_place},
                onSelectionChanged: (s) => setState(() => _place = s.first),
              ),
              const SizedBox(height: 10),
              const Text(Strings.shareHint, style: TextStyle(fontSize: 14, color: KidColors.inkSoft, height: 1.4)),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: _button,
                onPressed: _sharing ? null : () => _share(chosen),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: KidColors.skyDark),
                icon: const KidIcon('share', size: 22, color: Colors.white),
                label: const Text(Strings.shareNow, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ]),
    );
  }
}

/// The card a shared postcard becomes, 4 by 5 (fits LINE, IG and a phone).
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.postcard, required this.picture, required this.avatar, this.place = SharedPlace.kind});

  final Postcard postcard;
  final ImageProvider picture;
  final String avatar;
  final SharedPlace place;

  /// What the child's animal says on it.
  static String lineFor(Postcard postcard) =>
      Creature.byName(postcard.artwork.template) != null ? Strings.shareLineCreature : Strings.shareLineMine;

  @override
  Widget build(BuildContext context) {
    final sent = postcard.artwork.sentAt ?? postcard.artwork.updatedAt;
    final kind = PlaceKind.byName(postcard.place.kind);
    final where = switch (place) {
      SharedPlace.kind => kind.label,
      SharedPlace.name => postcard.place.label ?? kind.label,
      SharedPlace.none => null,
    };
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: LayoutBuilder(builder: (context, box) {
        final u = box.maxWidth / 100; // card units: 100 across
        return ClipRRect(
          borderRadius: BorderRadius.circular(4 * u),
          child: PaperBackground(
            child: Padding(
              padding: EdgeInsets.fromLTRB(6 * u, 6 * u, 6 * u, 4 * u),
              child: Column(children: [
                Expanded(
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(
                      left: 2 * u,
                      right: 2 * u,
                      bottom: 8 * u,
                      child: PostcardFrame(
                        tilt: -1.5,
                        padding: 3 * u,
                        radius: 5 * u,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3 * u),
                          child: Image(image: picture, fit: BoxFit.contain, gaplessPlayback: true,
                              errorBuilder: (_, _, _) => const ColoredBox(color: Colors.white)),
                        ),
                      ),
                    ),
                    Positioned(right: -1 * u, top: -2 * u, child: Postmark(shortDate(sent).replaceAll('/', '.'), size: 15 * u)),
                    Positioned(
                      left: -2 * u,
                      bottom: -1 * u,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Transform.rotate(angle: -0.12, child: AnimalArt(avatar, size: 17 * u)),
                        SizedBox(width: 1 * u),
                        Container(
                          margin: EdgeInsets.only(bottom: 8 * u),
                          padding: EdgeInsets.symmetric(horizontal: 3.4 * u, vertical: 2 * u),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5 * u),
                            boxShadow: KidShadows.soft(),
                          ),
                          child: Text(lineFor(postcard), style: TextStyle(fontSize: 4.2 * u, fontWeight: FontWeight.w700, color: KidColors.ink)),
                        ),
                      ]),
                    ),
                  ]),
                ),
                SizedBox(height: 3 * u),
                Row(children: [
                  if (where != null) ...[
                    ArtSvg(Art.place(kind), size: 7 * u),
                    SizedBox(width: 1.5 * u),
                    Flexible(
                      child: Text(Strings.sentTo(where),
                          overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 4 * u, color: KidColors.inkSoft, fontWeight: FontWeight.w700)),
                    ),
                  ],
                  const Spacer(),
                  ArtSvg(Art.logo, size: 7 * u),
                  SizedBox(width: 1.5 * u),
                  Text(Strings.appName, style: TextStyle(fontSize: 4.4 * u, fontWeight: FontWeight.w700, color: KidColors.ink)),
                ]),
              ]),
            ),
          ),
        );
      }),
    );
  }
}
