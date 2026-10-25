import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/celebration.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/creatures.dart';
import '../../core/db/database.dart';
import '../../core/providers.dart';
import '../../core/repositories.dart';
import '../town/place_sheet.dart';
import 'motion.dart';

/// Inside the zoo or the aquarium: every creature the child colored for it
/// walks, hops, swims or floats around; tap one and it jumps. The big
/// button picks a new creature to color, and when it is done it moves in.
class SceneScreen extends ConsumerStatefulWidget {
  const SceneScreen({super.key, required this.habitat, this.arrived});

  final Habitat habitat;

  /// A creature that was just colored: it gets a welcome.
  final int? arrived;

  @override
  ConsumerState<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends ConsumerState<SceneScreen> with SingleTickerProviderStateMixin {
  /// Seconds since the scene opened drive every creature's pose.
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(minutes: 10))..repeat();
  bool _opening = false;
  bool _welcome = false;
  Timer? _welcomeTimer;

  @override
  void initState() {
    super.initState();
    if (widget.arrived != null) {
      _welcome = true;
      _welcomeTimer = Timer(const Duration(milliseconds: 3200), () {
        if (mounted) setState(() => _welcome = false);
      });
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _welcomeTimer?.cancel();
    super.dispose();
  }

  String get _place => widget.habitat.place.label;

  Future<void> _draw(int childId, Creature creature) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final png = await rootBundle.load(Art.page(creature.name));
      final artwork = await ref.read(artworkServiceProvider).saveTemplate(
            childId: childId,
            template: creature.name,
            png: png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
          );
      if (mounted) unawaited(context.push('/canvas/${artwork.id}'));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _pick(int childId) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: KidColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
            for (final c in widget.habitat.creatures)
              ChunkyButton(
                key: ValueKey('creature-${c.name}'),
                label: Strings.drawCreature(c.label),
                width: 104,
                height: 120,
                radius: 28,
                onPressed: () {
                  Navigator.of(sheet).pop();
                  _draw(childId, c);
                },
                child: ArtSvg(Art.creature(c), width: 84, height: 108),
              ),
          ]),
        ),
      ),
    );
  }

  void _postcards(List<Postcard> postcards) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KidColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      builder: (sheet) => PlaceSheet(
        kind: widget.habitat.place,
        postcards: postcards,
        onDrawHere: () {
          Navigator.of(sheet).pop();
          ref.read(preferredPlaceProvider.notifier).choose(widget.habitat.place);
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
    final residents = child == null
        ? const <Artwork>[]
        : ref.watch(residentsProvider((childId: child.id, habitat: widget.habitat))).value ?? const <Artwork>[];
    final postcards = child == null
        ? const <Postcard>[]
        : [for (final p in ref.watch(postcardsProvider(child.id)).value ?? const <Postcard>[]) if (p.place.kind == widget.habitat.place.name) p];
    final store = ref.watch(artworkStoreProvider);
    final arrived = residents.where((a) => a.id == widget.arrived).firstOrNull;
    final arrivedCreature = Creature.byName(arrived?.template);
    final bubble = _welcome && arrivedCreature != null
        ? Strings.movedIn(arrivedCreature.label, _place)
        : (child != null && residents.isEmpty ? Strings.sceneEmpty(_place) : null);

    return Scaffold(
      body: LayoutBuilder(builder: (context, box) {
        final view = SceneView(box.biggest);
        final origin = view.origin;
        return Stack(children: [
          Positioned(
            left: origin.dx,
            top: origin.dy,
            width: 1000 * view.scale,
            height: 1000 * view.scale,
            child: ExcludeSemantics(child: SvgPicture.asset(Art.scene(widget.habitat), fit: BoxFit.fill)),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _clock,
              builder: (context, _) {
                final t = _clock.lastElapsedDuration?.inMicroseconds ?? 0;
                final seconds = t / 1e6;
                final placed = <({Artwork art, Creature creature, Pose pose})>[];
                for (final art in residents) {
                  final creature = Creature.byName(art.template);
                  if (creature == null) continue;
                  placed.add((art: art, creature: creature, pose: poseAt(creature.motion, seconds, art.id, roamArea(creature, view))));
                }
                // Farther back (higher up) first, so nearer creatures pass in front.
                placed.sort((a, b) => a.pose.at.dy.compareTo(b.pose.at.dy));
                return Stack(clipBehavior: Clip.none, children: [
                  for (final p in placed)
                    _Resident(
                      key: ValueKey(p.art.id),
                      creature: p.creature,
                      sprite: FileImage(store.open(p.art.folder).sprite),
                      pose: p.pose,
                      view: view,
                      arrived: p.art.id == widget.arrived,
                    ),
                ]);
              },
            ),
          ),
          if (_welcome && arrived != null) const Positioned.fill(child: IgnorePointer(child: Confetti())),
          SafeArea(
            child: Stack(children: [
              Positioned(
                left: 14,
                top: 10,
                child: NavButton(
                  icon: 'map',
                  label: Strings.backToTown,
                  color: KidColors.grassDark,
                  // Back to the town, which shows this place when it has to be rebuilt.
                  onPressed: () => context.canPop() ? context.pop() : context.go('/?focus=${widget.habitat.place.name}'),
                ),
              ),
              Positioned(top: 14, left: 0, right: 0, child: Center(child: _Title(habitat: widget.habitat))),
              if (postcards.isNotEmpty)
                Positioned(
                  right: 14,
                  top: 10,
                  child: Semantics(
                    button: true,
                    label: Strings.postcardsAt(_place, postcards.length),
                    excludeSemantics: true,
                    child: Pressable(
                      onTap: () => _postcards(postcards),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.fromLTRB(10, 0, 16, 0),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: KidShadows.soft()),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const KidIcon('mail', size: 26, color: KidColors.coral),
                          const SizedBox(width: 6),
                          Text('${postcards.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ),
                ),
              if (bubble != null)
                Positioned(
                  left: 24,
                  right: 24,
                  top: 86,
                  child: Center(child: PopIn(key: ValueKey(bubble), child: VoiceBubble(bubble))),
                ),
              Positioned(
                right: 18,
                bottom: 18,
                child: Breathing(
                  child: Semantics(
                    button: true,
                    label: Strings.drawNew(_place),
                    excludeSemantics: true,
                    child: Pressable(
                      onTap: child == null ? null : () => _pick(child.id),
                      child: Container(
                        width: 104,
                        height: 104,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: KidColors.sun,
                          border: Border.all(color: Colors.white, width: 6),
                          boxShadow: [BoxShadow(color: KidColors.sunDark.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: const Stack(alignment: Alignment.center, children: [
                          KidIcon('crayon', size: 50, color: Colors.white),
                          Positioned(right: 14, top: 14, child: KidIcon('plus', size: 26, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          if (_opening) const ModalBarrier(dismissible: false),
        ]);
      }),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.habitat});

  final Habitat habitat;

  @override
  Widget build(BuildContext context) => Container(
        height: 52,
        padding: const EdgeInsets.fromLTRB(6, 0, 18, 0),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: KidShadows.soft()),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ArtSvg(Art.place(habitat.place), size: 42),
          const SizedBox(width: 6),
          Text(habitat.place.label, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        ]),
      );
}

/// One colored creature at its [pose]; tap it and it jumps with hearts.
class _Resident extends StatefulWidget {
  const _Resident({super.key, required this.creature, required this.sprite, required this.pose, required this.view, this.arrived = false});

  final Creature creature;
  final ImageProvider sprite;
  final Pose pose;
  final SceneView view;
  final bool arrived;

  @override
  State<_Resident> createState() => _ResidentState();
}

class _ResidentState extends State<_Resident> with TickerProviderStateMixin {
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _arrive =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200), value: widget.arrived ? 0 : 1);

  @override
  void initState() {
    super.initState();
    if (widget.arrived) _arrive.forward();
  }

  @override
  void dispose() {
    _jump.dispose();
    _arrive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final pose = widget.pose;
    // Farther creatures (higher up) are a little smaller.
    final depth = 0.85 + 0.15 * ((pose.at.dy - 300) / 650).clamp(0.0, 1.0);
    final width = widget.creature.size * view.creatureScale * view.scale * depth;
    final at = view.toScreen(pose.at);
    return Positioned(
      left: at.dx - width / 2,
      bottom: view.screen.height - at.dy,
      width: width,
      child: Semantics(
        button: true,
        label: Strings.resident(widget.creature.label),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _jump.forward(from: 0),
          child: AnimatedBuilder(
            animation: Listenable.merge([_jump, _arrive]),
            builder: (context, child) {
              final hop = math.sin(math.pi * _jump.value) * 60 * view.scale;
              final grow = Curves.elasticOut.transform(_arrive.value);
              return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
                if (_arrive.value < 1)
                  Positioned(
                    bottom: -10,
                    child: Opacity(
                      opacity: 1 - _arrive.value,
                      child: Container(
                        width: width * (0.6 + _arrive.value),
                        height: width * 0.22,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(width), border: Border.all(color: KidColors.sun, width: 5)),
                      ),
                    ),
                  ),
                Transform.translate(
                  offset: Offset(0, -hop),
                  child: Transform.scale(
                    scale: 0.2 + 0.8 * grow,
                    alignment: Alignment.bottomCenter,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(pose.left ? -1 : 1, pose.squash, 1)..rotateZ(pose.tilt),
                      child: child,
                    ),
                  ),
                ),
                if (_jump.value > 0 && _jump.value < 1)
                  Positioned(
                    top: -28 - 30 * _jump.value,
                    child: Opacity(
                      opacity: 1 - _jump.value,
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        KidIcon('heart', size: 22, color: KidColors.coral, solid: true),
                        SizedBox(width: 4),
                        KidIcon('heart', size: 16, color: KidColors.coral, solid: true),
                      ]),
                    ),
                  ),
              ]);
            },
            child: Image(image: widget.sprite, gaplessPlayback: true, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
