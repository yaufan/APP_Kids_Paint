import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/celebration.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/db/database.dart';
import '../../core/festivals.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import '../../core/repositories.dart';
import '../../core/town_time.dart';
import '../parent/parent_gate.dart';
import 'place_sheet.dart';
import 'town_map.dart';

/// Home: the child's town. Postcards are pinned where they were sent; the
/// big camera button starts a new picture, the paper a free drawing. The
/// town follows the clock (day, dusk, night) and Taiwan's festivals, when
/// Gugu brings a festival's coloring page.
class TownScreen extends ConsumerStatefulWidget {
  const TownScreen({super.key, this.focus, this.grow});

  /// A postcard just arrived here.
  final PlaceKind? focus;

  /// ...and it was the first one, so the place was just built.
  final PlaceKind? grow;

  @override
  ConsumerState<TownScreen> createState() => _TownScreenState();
}

class _TownScreenState extends ConsumerState<TownScreen> {
  String? _bubble;
  Timer? _bubbleTimer;

  /// Redraws when the time of day changes while the town is open.
  Timer? _tick;
  bool _opening = false;

  /// The evening Gugu last said good night, once per evening.
  static DateTime? _saidGoodnight;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final now = ref.read(clockProvider)();
      final today = DateTime(now.year, now.month, now.day);
      if (mounted && widget.focus == null && dayPhaseAt(now) == DayPhase.night && _saidGoodnight != today) {
        _saidGoodnight = today;
        _say(Strings.bedtime);
      }
    });
  }

  @override
  void dispose() {
    _bubbleTimer?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  /// Opens a new page ([make] saves it) on the canvas; one at a time.
  Future<void> _open(Future<Artwork> Function() make) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final artwork = await make();
      // Not awaited: the canvas leaves with go('/'), which never completes a push.
      if (mounted) unawaited(context.push('/canvas/${artwork.id}'));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _openBlank(int childId) => _open(() => ref.read(artworkServiceProvider).saveBlank(childId: childId));

  Future<void> _openFestivalPage(int childId, Festival festival) => _open(() async {
        final png = await rootBundle.load(Art.page(festival));
        return ref.read(artworkServiceProvider).saveTemplate(
              childId: childId,
              template: festival.name,
              png: png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
            );
      });

  void _say(String text) {
    _bubbleTimer?.cancel();
    setState(() => _bubble = text);
    _bubbleTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  void _openPlace(PlaceKind kind, List<Postcard> postcards) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KidColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      builder: (sheet) => PlaceSheet(
        kind: kind,
        postcards: [for (final p in postcards) if (p.place.kind == kind.name) p],
        onDrawHere: () {
          Navigator.of(sheet).pop();
          ref.read(preferredPlaceProvider.notifier).choose(kind);
          context.push('/capture');
        },
        onOpen: (artwork) {
          Navigator.of(sheet).pop();
          context.push('/canvas/${artwork.id}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(currentChildProvider).value;
    final postcards = child == null ? const <Postcard>[] : ref.watch(postcardsProvider(child.id)).value ?? const [];
    final now = ref.watch(clockProvider)();
    final spots = townSpots(postcards, now);
    final store = ref.watch(artworkStoreProvider);
    final avatar = child?.avatar ?? animals.first;
    final name = animalNames[avatar] ?? '';
    final festival = festivalOn(now);
    // Gugu brings the festival's page until the child opens it.
    final letter = child != null &&
            festival != null &&
            festival.festival.hasPage &&
            ref.watch(festivalPageOpenedProvider((childId: child.id, festival: festival.festival, since: festival.first))).value == false
        ? festival.festival
        : null;
    final bubble = _bubble ?? (letter != null ? Strings.festivalLetter(letter.label) : (child != null && postcards.isEmpty ? Strings.emptyTown : null));

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: TownMap(
            spots: spots,
            thumbnailOf: (a) => store.open(a.folder).thumbnail,
            avatar: avatar,
            focus: widget.focus,
            grow: widget.grow,
            phase: dayPhaseAt(now),
            festival: festival?.festival,
            onPin: (kind) => _openPlace(kind, postcards),
            onLot: (_) => _say(Strings.emptyLot),
          ),
        ),
        if (widget.grow != null) const Positioned.fill(child: Confetti()),
        SafeArea(
          child: Stack(children: [
            Positioned(left: 14, top: 10, child: _ChildPill(avatar: avatar, name: name)),
            Positioned(right: 66, top: 17, child: _PostcardCount(count: postcards.length)),
            Positioned(
              right: 14,
              top: 17,
              child: ParentLockButton(onPressed: () async {
                if (await showParentGate(context) && context.mounted) context.push('/parent');
              }),
            ),
            if (widget.grow != null)
              Positioned(
                left: 0,
                right: 0,
                top: 88,
                child: Center(child: PopIn(delay: const Duration(milliseconds: 500), child: _NewPlaceBanner(kind: widget.grow!))),
              ),
            if (bubble != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 190,
                child: Center(child: PopIn(key: ValueKey(bubble), child: VoiceBubble(bubble))),
              ),
            if (letter != null)
              Positioned(
                right: 18,
                bottom: 284,
                child: PopIn(
                  delay: const Duration(milliseconds: 400),
                  child: _FestivalLetter(festival: letter, onTap: () => _openFestivalPage(child!.id, letter)),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _Dock(onPaper: child == null ? null : () => _openBlank(child.id)),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ChildPill extends ConsumerWidget {
  const _ChildPill({required this.avatar, required this.name});

  final String avatar;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider).value ?? const <Child>[];
    return Semantics(
      button: children.length > 1,
      label: Strings.switchChild,
      child: Pressable(
        onTap: children.length < 2
            ? null
            : () => showModalBottomSheet<void>(
                  context: context,
                  backgroundColor: KidColors.paper,
                  builder: (sheet) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Wrap(spacing: 18, runSpacing: 18, alignment: WrapAlignment.center, children: [
                        for (final c in children)
                          ChunkyButton(
                            label: animalNames[c.avatar] ?? c.avatar,
                            width: 96,
                            height: 96,
                            radius: 30,
                            onPressed: () {
                              ref.read(currentChildIdProvider.notifier).select(c.id);
                              Navigator.of(sheet).pop();
                            },
                            child: AnimalArt(c.avatar, size: 72),
                          ),
                      ]),
                    ),
                  ),
                ),
        child: Container(
          height: 56,
          padding: const EdgeInsets.fromLTRB(5, 0, 16, 0),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: KidShadows.soft()),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0xFFFFF1DA), shape: BoxShape.circle),
              child: AnimalArt(avatar, size: 40),
            ),
            const SizedBox(width: 8),
            Text(Strings.townOf(name), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

class _PostcardCount extends StatelessWidget {
  const _PostcardCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Strings.postcardsSent(count),
      excludeSemantics: true,
      child: Container(
        height: 42,
        padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21), boxShadow: KidShadows.soft()),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: KidColors.coral, borderRadius: BorderRadius.circular(9)),
            child: const KidIcon('mail', size: 18, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _NewPlaceBanner extends StatelessWidget {
  const _NewPlaceBanner({required this.kind});

  final PlaceKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(10, 0, 22, 0),
      decoration: BoxDecoration(
        color: KidColors.sun,
        borderRadius: BorderRadius.circular(32),
        boxShadow: KidShadows.chunky(KidColors.sunDark, 6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ArtSvg(Art.place(kind), size: 52),
        const SizedBox(width: 8),
        Text(Strings.newPlace(kind.label), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// Gugu with a festival's letter: tap it to color that festival's page.
class _FestivalLetter extends StatelessWidget {
  const _FestivalLetter({required this.festival, required this.onTap});

  final Festival festival;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: Strings.openLetter(festival.label),
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          child: Breathing(
            child: SizedBox(
              width: 104,
              height: 104,
              child: Stack(clipBehavior: Clip.none, children: [
                const ArtSvg(Art.pigeon, size: 96),
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: KidShadows.soft()),
                    child: ArtSvg(Art.festival(festival), size: 38),
                  ),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// The album, the big camera button and blank paper.
class _Dock extends StatelessWidget {
  const _Dock({required this.onPaper});

  final VoidCallback? onPaper;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
        Container(
          height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), boxShadow: KidShadows.soft()),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: [
            _DockTile(label: Strings.album, art: Art.miniAlbum, color: const Color(0xFFE8F3FF), onTap: () => context.push('/album')),
            const Spacer(),
            _DockTile(label: Strings.blankPaper, art: Art.miniPaper, color: const Color(0xFFFFF3D6), onTap: onPaper),
          ]),
        ),
        Positioned(
          bottom: 30,
          child: Breathing(
            child: Semantics(
              button: true,
              label: Strings.takePhoto,
              excludeSemantics: true,
              child: Pressable(
                onTap: () => context.push('/capture'),
                child: Container(
                  width: KidTheme.cameraButton,
                  height: KidTheme.cameraButton,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 7),
                    gradient: const RadialGradient(
                      center: Alignment(-0.3, -0.45),
                      colors: [Color(0xFFFF9A8C), KidColors.coral, KidColors.coralDark],
                      stops: [0, 0.58, 1],
                    ),
                    boxShadow: [BoxShadow(color: KidColors.coralDark.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 16))],
                  ),
                  child: const KidIcon('camera', size: 58, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DockTile extends StatelessWidget {
  const _DockTile({required this.label, required this.art, required this.color, required this.onTap});

  final String label;
  final String art;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
            child: ArtSvg(art, size: 48),
          ),
        ),
      );
}
