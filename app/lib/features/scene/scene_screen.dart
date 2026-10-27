import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/celebration.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/creature_lines.dart';
import '../../core/creatures.dart';
import '../../core/db/database.dart';
import '../../core/festivals.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import '../../core/repositories.dart';
import '../../core/voice.dart';
import '../town/place_sheet.dart';
import 'motion.dart';

/// Inside a place you can go into: every creature the child colored for it
/// walks, hops, swims, floats or flies around (in the shop the goods stand
/// on the shelves) and now and then says something that fits the moment
/// (read out loud unless parents turned voices off); tap one and it jumps
/// and talks. The big button picks a new creature to color, and when it is
/// done it moves in.
///
/// In the shop customers come in now and then (the child's own animals, or
/// the buddies), ask for one of the goods, take it home and pay a coin;
/// the shelf is filled again right away. In space a tapped rocket counts
/// down and takes off (now and then one does by itself) and the stars
/// twinkle; at the night market the lanterns glow and a tapped snack gets
/// a ring thrown over it; at the polar sea it snows.
class SceneScreen extends ConsumerStatefulWidget {
  const SceneScreen({super.key, required this.habitat, this.arrived});

  final Habitat habitat;

  /// A creature that was just colored: it gets a welcome.
  final int? arrived;

  @override
  ConsumerState<SceneScreen> createState() => _SceneScreenState();
}

class _SceneScreenState extends ConsumerState<SceneScreen> with TickerProviderStateMixin {
  /// Seconds since the scene opened drive every creature's pose.
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(minutes: 10))..repeat();
  bool _opening = false;
  bool _welcome = false;
  Timer? _welcomeTimer;

  /// Who is talking (an artwork id) and what they say.
  ({int id, String text})? _saying;
  Timer? _chatter;
  Timer? _hello;
  Timer? _hush;
  Voice? _voice;
  final _random = math.Random();
  List<Artwork> _residents = const [];

  /// Taps in a row on a creature (an artwork id): how many, and when the
  /// last was (on the scene's clock).
  final _taps = <int, ({int count, Duration at})>{};
  bool _greeted = false;

  // The shop's customers.
  late final AnimationController _visit = AnimationController(vsync: this, duration: const Duration(milliseconds: 7500));
  Timer? _customers;
  Timer? _firstCustomer;
  _Sale? _sale;
  int _coins = 0;

  /// Goods on the shelves now, and who may come to buy them.
  List<Artwork> _shelved = const [];
  List<Artwork> _customerArts = const [];

  bool get _shop => widget.habitat == Habitat.shop;

  /// The shelves goods stand on here, if any.
  List<double>? get _shelves => switch (widget.habitat) {
        Habitat.shop => shopBoards,
        Habitat.nightMarket => marketCounters,
        _ => null,
      };

  // Space: a rocket taking off (an artwork id).
  late final AnimationController _liftoff = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
  int? _launching;
  Timer? _launches;

  // The night market: a ring thrown at a snack (an artwork id), landing at
  // [at] (scene units, around the snack) and as wide as [width].
  late final AnimationController _throw = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  ({int id, Offset at, double width})? _ring;

  @override
  void initState() {
    super.initState();
    if (widget.arrived != null) {
      _welcome = true;
      _welcomeTimer = Timer(const Duration(milliseconds: 3200), () {
        if (mounted) setState(() => _welcome = false);
      });
    }
    // Every few seconds someone says something; a new arrival says hello first.
    _chatter = Timer.periodic(const Duration(milliseconds: 6500), (_) => _chat());
    _hello = Timer(Duration(milliseconds: widget.arrived != null ? 1600 : 2500), () {
      final arrived = _residents.where((a) => a.id == widget.arrived).firstOrNull;
      arrived != null ? _say(arrived) : _chat();
    });
    if (widget.habitat == Habitat.space) {
      _launches = Timer.periodic(const Duration(seconds: 17), (_) {
        final rockets = [for (final a in _residents) if (a.template == Creature.rocket.name) a];
        if (rockets.isNotEmpty) _launch(rockets[_random.nextInt(rockets.length)]);
      });
      _liftoff.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _launching = null);
      });
    }
    _throw.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) setState(() => _ring = null);
    });
    if (_shop) {
      _firstCustomer = Timer(const Duration(milliseconds: 5000), _startSale);
      _customers = Timer.periodic(const Duration(seconds: 13), (_) => _startSale());
      _visit.addListener(_onVisit);
      _visit.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) setState(() => _sale = null);
      });
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _welcomeTimer?.cancel();
    _chatter?.cancel();
    _hello?.cancel();
    _hush?.cancel();
    _customers?.cancel();
    _firstCustomer?.cancel();
    _launches?.cancel();
    _visit.dispose();
    _liftoff.dispose();
    _throw.dispose();
    _voice?.stop();
    super.dispose();
  }

  /// A random creature (not the one that just spoke) says something.
  void _chat() {
    if (!mounted || _residents.isEmpty || _sale != null) return;
    final others = [for (final a in _residents) if (a.id != _saying?.id) a];
    _say((others.isEmpty ? _residents : others)[_random.nextInt(others.isEmpty ? _residents.length : others.length)]);
  }

  void _say(Artwork art, {bool tapped = false}) {
    final creature = Creature.byName(art.template);
    if (!mounted || creature == null) return;
    final now = ref.read(clockProvider)();
    var taps = 0;
    if (tapped) {
      final at = _clock.lastElapsedDuration ?? Duration.zero, last = _taps[art.id];
      taps = last != null && at - last.at < const Duration(seconds: 5) ? last.count + 1 : 1;
      _taps[art.id] = (count: taps, at: at);
    }
    final arrived = art.id == widget.arrived && !_greeted;
    if (arrived) _greeted = true;
    final moment = Moment(
      time: now,
      festival: festivalOn(now)?.festival,
      justArrived: arrived,
      neighbors: [for (final a in _residents) if (a.id != art.id) ?Creature.byName(a.template)],
      taps: taps,
    );
    _speak(art.id, lineFor(creature, _random, moment));
  }

  /// [id] (an artwork; 0 for a customer) says [text] in a bubble and out loud.
  void _speak(int id, String text) {
    setState(() => _saying = (id: id, text: text));
    final voice = ref.read(voiceProvider);
    _voice = voice;
    voice.say(text);
    _hush?.cancel();
    _hush = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _saying = null);
    });
  }

  /// A rocket counts down and takes off, and lands again a moment later.
  void _launch(Artwork rocket) {
    if (!mounted || _launching != null) return;
    setState(() => _launching = rocket.id);
    _speak(rocket.id, countdown);
    _liftoff.forward(from: 0);
  }

  /// How high the launching rocket is (scene units), and whether its engine
  /// is burning, at [t] of the launch: the countdown, up and away, then
  /// back down from the top.
  static ({double lift, bool flame, double shake}) _flight(double t) {
    if (t < 0.32) return (lift: 0, flame: t > 0.22, shake: t > 0.12 ? math.sin(t * 160) * 3 : 0);
    if (t < 0.62) return (lift: 1500 * Curves.easeIn.transform((t - 0.32) / 0.3), flame: true, shake: 0);
    if (t < 0.72) return (lift: 1500, flame: false, shake: 0);
    return (lift: 1500 * (1 - Curves.easeOut.transform((t - 0.72) / 0.28)), flame: t < 0.95, shake: 0);
  }

  /// A ring flies over a snack at the night market; it says something when
  /// it lands.
  void _toss(Artwork snack, Pose pose, Creature creature) {
    if (!mounted || _ring != null) return;
    setState(() => _ring = (id: snack.id, at: pose.at - const Offset(0, 34), width: math.max(70.0, creature.size * 1.15)));
    _throw.forward(from: 0);
    Timer(const Duration(milliseconds: 900), () {
      if (mounted && _ring?.id == snack.id) _speak(snack.id, ringed[_random.nextInt(ringed.length)]);
    });
  }

  /// A customer comes in for one of the goods on the shelves.
  void _startSale() {
    if (!mounted || _sale != null || _shelved.isEmpty) return;
    final item = _shelved[_random.nextInt(_shelved.length)];
    final creature = Creature.byName(item.template);
    if (creature == null) return;
    final who = _customerArts.isEmpty ? null : _customerArts[_random.nextInt(_customerArts.length)];
    setState(() => _sale = _Sale(
          item: item,
          customer: who,
          buddy: animals[_random.nextInt(animals.length)],
          asks: wantToBuy(creature, _random),
          thanks: soldLines[_random.nextInt(soldLines.length)],
        ));
    _visit.forward(from: 0);
  }

  /// The sale's moments: asking, then paying.
  void _onVisit() {
    final sale = _sale;
    if (sale == null || !mounted) return;
    if (!sale.asked && _visit.value >= _Sale.ask) {
      sale.asked = true;
      _speak(0, sale.asks);
    }
    if (!sale.paid && _visit.value >= _Sale.pay) {
      sale.paid = true;
      setState(() => _coins++);
      _speak(sale.item.id, sale.thanks);
    }
  }

  String get _place => widget.habitat.label;

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
                child: ExcludeSemantics(child: Image.asset(Art.page(c.name), width: 84, height: 108, cacheWidth: 168)),
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
    _residents = residents;
    if (_shop && child != null) _customerArts = ref.watch(shopCustomersProvider(child.id)).value ?? const [];
    final store = ref.watch(artworkStoreProvider);
    final arrived = residents.where((a) => a.id == widget.arrived).firstOrNull;
    final arrivedCreature = Creature.byName(arrived?.template);
    final bubble = _welcome && arrivedCreature != null
        ? Strings.movedIn(arrivedCreature.label, _place, residents: widget.habitat.residents)
        : (child != null && residents.isEmpty ? Strings.sceneEmpty(_place, residents: widget.habitat.residents) : null);

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
            child: ExcludeSemantics(child: Image.asset(Art.scene(widget.habitat), fit: BoxFit.fill, gaplessPlayback: true)),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _clock,
              builder: (context, _) {
                final t = _clock.lastElapsedDuration?.inMicroseconds ?? 0;
                final seconds = t / 1e6;
                final placed = <({Artwork art, Creature creature, Pose pose})>[];
                final shelves = _shelves;
                final spots = shelves == null ? const <Offset>[] : shelfSpots(view, boards: shelves);
                final shelved = <Artwork>[];
                for (final art in residents) {
                  final creature = Creature.byName(art.template);
                  if (creature == null) continue;
                  final Rect area;
                  if (creature.motion == Motion.shelf) {
                    if (shelved.length >= spots.length) continue; // the shelves on screen are full
                    area = Rect.fromPoints(spots[shelved.length], spots[shelved.length]);
                    shelved.add(art);
                  } else {
                    area = roamArea(creature, view);
                  }
                  placed.add((art: art, creature: creature, pose: poseAt(creature.motion, seconds, art.id, area)));
                }
                _shelved = shelved;
                final sale = _sale;
                final sold = sale == null ? null : placed.where((p) => p.art.id == sale.item.id).firstOrNull;
                // Farther back (higher up) first, so nearer creatures pass in front.
                placed.sort((a, b) => a.pose.at.dy.compareTo(b.pose.at.dy));
                final flight = _launching == null ? null : _flight(_liftoff.value);
                return Stack(clipBehavior: Clip.none, children: [
                  if (widget.habitat == Habitat.space || widget.habitat == Habitat.nightMarket)
                    Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _Glow(widget.habitat, view, seconds)))),
                  for (final p in placed)
                    _Resident(
                      key: ValueKey(p.art.id),
                      creature: p.creature,
                      sprite: FileImage(store.open(p.art.folder).sprite),
                      pose: p.pose,
                      view: view,
                      arrived: p.art.id == widget.arrived,
                      saying: _saying?.id == p.art.id ? _saying!.text : null,
                      presence: sale != null && sale.item.id == p.art.id ? sale.presence(_visit.value) : 1,
                      lift: _launching == p.art.id ? flight!.lift : 0,
                      flame: _launching == p.art.id && flight!.flame,
                      shake: _launching == p.art.id ? flight!.shake : 0,
                      onTap: () => switch (p.creature) {
                        Creature.rocket => _launch(p.art),
                        _ when widget.habitat == Habitat.nightMarket && p.creature.motion == Motion.shelf => _toss(p.art, p.pose, p.creature),
                        _ => _say(p.art, tapped: true),
                      },
                    ),
                  if (_ring case final ring?) _Ring(ring: ring, t: _throw.value, view: view),
                  if (widget.habitat == Habitat.polar)
                    Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _Snow(view, seconds)))),
                  if (sale != null && sold != null)
                    _Customer(
                      sale: sale,
                      t: _visit.value,
                      seconds: seconds,
                      view: view,
                      standAt: sold.pose.at.dx,
                      sprite: sale.customer == null ? null : FileImage(store.open(sale.customer!.folder).sprite),
                      customerSize: Creature.byName(sale.customer?.template)?.size,
                      item: FileImage(store.open(sale.item.folder).sprite),
                      itemSize: sold.creature.size,
                      saying: _saying?.id == 0 ? _saying!.text : null,
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
              if (_shop)
                Positioned(
                  right: 14,
                  top: postcards.isNotEmpty ? 76 : 10,
                  child: Semantics(
                    label: Strings.coins(_coins),
                    excludeSemantics: true,
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_coins),
                      tween: Tween(begin: _coins == 0 ? 1 : 1.35, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.fromLTRB(10, 0, 16, 0),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: KidShadows.soft()),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const _Coin(size: 30),
                          const SizedBox(width: 6),
                          Text('$_coins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                    label: Strings.drawNew(_place, residents: widget.habitat.residents),
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
          Text(habitat.label, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        ]),
      );
}

/// One colored creature at its [pose]; tap it and it jumps with hearts.
class _Resident extends StatefulWidget {
  const _Resident({
    super.key,
    required this.creature,
    required this.sprite,
    required this.pose,
    required this.view,
    this.arrived = false,
    this.saying,
    this.presence = 1,
    this.lift = 0,
    this.flame = false,
    this.shake = 0,
    this.onTap,
  });

  final Creature creature;
  final ImageProvider sprite;
  final Pose pose;
  final SceneView view;
  final bool arrived;

  /// What it is saying, shown in a bubble over its head.
  final String? saying;

  /// How much of it is there: 0 while a customer has it, growing back to 1
  /// when the shelf is filled again.
  final double presence;

  /// A rocket taking off: how high it is (scene units), whether its engine
  /// burns, and how much it shakes before it goes.
  final double lift;
  final bool flame;
  final double shake;
  final VoidCallback? onTap;

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
    // Farther creatures (higher up) are a little smaller; goods on a shelf
    // keep their size ([shelfSpots]).
    final shelf = widget.creature.motion == Motion.shelf;
    final depth = shelf ? 1.0 : 0.85 + 0.15 * ((pose.at.dy - 300) / 650).clamp(0.0, 1.0);
    final width = widget.creature.size * (shelf ? 1.0 : view.creatureScale) * view.scale * depth;
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
          onTap: () {
            _jump.forward(from: 0);
            widget.onTap?.call();
          },
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
                if (widget.flame)
                  Positioned(
                    bottom: -width * 0.45 + widget.lift * view.scale,
                    child: _Flame(width: width * 0.36, flicker: math.sin(DateTime.now().millisecondsSinceEpoch / 40)),
                  ),
                Transform.translate(
                  offset: Offset(widget.shake * view.scale, -hop - widget.lift * view.scale),
                  child: Transform.scale(
                    scale: (0.2 + 0.8 * grow) * widget.presence,
                    alignment: Alignment.bottomCenter,
                    child: Transform(
                      alignment: Alignment.bottomCenter,
                      transform: Matrix4.diagonal3Values(pose.left ? -1 : 1, pose.squash, 1)..rotateZ(pose.tilt),
                      child: child,
                    ),
                  ),
                ),
                if (widget.saying case final text?)
                  Positioned(
                    left: -70,
                    right: -70,
                    top: -58 - hop - widget.lift * view.scale,
                    child: Center(child: PopIn(key: ValueKey(text), child: _SpeechBubble(text))),
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

/// A creature's words, in a little bubble pointing down at it.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 190),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: KidShadows.soft()),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.3)),
        ),
        CustomPaint(size: const Size(16, 9), painter: _TailPainter()),
      ]);
}

class _TailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = Colors.white);

  @override
  bool shouldRepaint(_TailPainter old) => false;
}

/// One customer's visit to the shop, over the visit's animation (0 to 1):
/// walking in, asking, taking the goods, paying, walking out; the shelf is
/// filled again before they are gone.
class _Sale {
  _Sale({required this.item, required this.customer, required this.buddy, required this.asks, required this.thanks});

  /// What they buy.
  final Artwork item;

  /// One of the child's own animals, or else a [buddy].
  final Artwork? customer;
  final String buddy;
  final String asks;
  final String thanks;
  bool asked = false, paid = false;

  static const arrive = 0.33, ask = 0.36, take = 0.5, pay = 0.55, leave = 0.6, restock = 0.8;

  double presence(double t) {
    if (t < take) return 1;
    if (t < restock) return 0;
    return Curves.elasticOut.transform(((t - restock) / (1 - restock)).clamp(0.0, 1.0));
  }
}

/// A customer walking along the shop's floor; with the goods over their
/// head once they have bought them.
class _Customer extends StatelessWidget {
  const _Customer({
    required this.sale,
    required this.t,
    required this.seconds,
    required this.view,
    required this.standAt,
    required this.sprite,
    required this.customerSize,
    required this.item,
    required this.itemSize,
    this.saying,
  });

  final _Sale sale;
  final double t, seconds;
  final SceneView view;

  /// Where they stop, under the goods (scene units).
  final double standAt;
  final ImageProvider? sprite;
  final double? customerSize;
  final ImageProvider item;
  final double itemSize;
  final String? saying;

  static const floor = 985.0;

  @override
  Widget build(BuildContext context) {
    final v = view.visible;
    final width = (customerSize == null ? 90 : customerSize! * 0.75) * view.creatureScale;
    final stand = standAt.clamp(v.left + width / 2, v.right - width / 2);
    final double x;
    if (t < _Sale.arrive) {
      x = v.left - width + (stand - v.left + width) * Curves.easeOut.transform(t / _Sale.arrive);
    } else if (t < _Sale.leave) {
      x = stand;
    } else {
      x = stand + (v.right + width - stand) * Curves.easeIn.transform((t - _Sale.leave) / (1 - _Sale.leave));
    }
    final walking = t < _Sale.arrive || t >= _Sale.leave;
    final bob = walking ? 8 * math.sin(seconds * 12).abs() : 0.0;
    final at = view.toScreen(Offset(x, floor - bob));
    final w = width * view.scale;
    final carrying = t >= _Sale.take;
    final carry = Curves.elasticOut.transform(((t - _Sale.take) / 0.15).clamp(0.0, 1.0));
    final room = math.max(w * 2, 220.0); // for the speech bubble
    return Positioned(
      left: at.dx - room / 2,
      width: room,
      bottom: view.screen.height - at.dy,
      child: Semantics(
        label: Strings.customer,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (saying case final text?) PopIn(key: ValueKey(text), child: _SpeechBubble(text)),
          if (carrying)
            Transform.scale(
              scale: carry,
              alignment: Alignment.bottomCenter,
              child: Image(image: item, width: itemSize * 0.6 * view.scale, gaplessPlayback: true),
            ),
          SizedBox(
            width: w,
            child: sprite != null ? Image(image: sprite!, gaplessPlayback: true, fit: BoxFit.contain) : AnimalArt(sale.buddy, size: w),
          ),
        ]),
      ),
    );
  }
}

/// A gold coin.
class _Coin extends StatelessWidget {
  const _Coin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: KidColors.sun,
          shape: BoxShape.circle,
          border: Border.all(color: KidColors.sunDark, width: size * 0.09),
        ),
        child: KidIcon('star', size: size * 0.5, color: Colors.white, solid: true),
      );
}

/// A rocket's flame.
class _Flame extends StatelessWidget {
  const _Flame({required this.width, required this.flicker});

  final double width;
  final double flicker;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width * (1.5 + 0.15 * flicker),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(width * 0.2), bottom: Radius.circular(width)),
            gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [KidColors.sun, KidColors.coral, Color(0x00FF5E5B)]),
          ),
        ),
      );
}

/// A ring thrown at a snack: it flies up from the bottom of the screen in
/// an arc, then lies around the snack for a moment.
class _Ring extends StatelessWidget {
  const _Ring({required this.ring, required this.t, required this.view});

  final ({int id, Offset at, double width}) ring;
  final double t;
  final SceneView view;

  static const _flying = 0.5;

  @override
  Widget build(BuildContext context) {
    final v = view.visible;
    final start = Offset(v.center.dx, v.bottom + 40);
    final f = (t / _flying).clamp(0.0, 1.0), e = Curves.easeOut.transform(f);
    final at = Offset.lerp(start, ring.at, e)! - Offset(0, 300 * 4 * f * (1 - f));
    final landed = t >= _flying;
    final width = (landed ? ring.width : 80 + (ring.width - 80) * e) * view.scale;
    final height = landed ? width * 0.32 : width * (1 - 0.68 * e);
    final fade = t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15).clamp(0.0, 1.0);
    final screen = view.toScreen(at);
    return Positioned(
      left: screen.dx - width / 2,
      top: screen.dy - height / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: fade,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.elliptical(width / 2, height / 2)),
              border: Border.all(color: KidColors.coral, width: 7 * view.scale + 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// Space's twinkling stars, or the night market's glowing lanterns.
class _Glow extends CustomPainter {
  _Glow(this.habitat, this.view, this.seconds);

  final Habitat habitat;
  final SceneView view;
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    if (habitat == Habitat.nightMarket) {
      for (final (i, lantern) in marketLanterns.indexed) {
        final glow = 0.25 + 0.15 * math.sin(seconds * 2.2 + i * 1.7);
        paint.shader = RadialGradient(colors: [const Color(0xFFFFE08A).withValues(alpha: glow), const Color(0x00FFE08A)])
            .createShader(Rect.fromCircle(center: view.toScreen(lantern), radius: 46 * view.scale));
        canvas.drawCircle(view.toScreen(lantern), 46 * view.scale, paint);
      }
      return;
    }
    final r = math.Random(11);
    for (var i = 0; i < 40; i++) {
      final at = view.toScreen(Offset(r.nextDouble() * 1000, r.nextDouble() * 720));
      final twinkle = 0.5 + 0.5 * math.sin(seconds * (1.5 + r.nextDouble() * 2) + i);
      paint
        ..shader = null
        ..color = Colors.white.withValues(alpha: 0.2 + 0.7 * twinkle);
      canvas.drawCircle(at, (1.2 + 2.2 * twinkle) * view.scale + 0.6, paint);
    }
  }

  @override
  bool shouldRepaint(_Glow old) => old.seconds != seconds;
}

/// Snow falling gently over the polar sea.
class _Snow extends CustomPainter {
  _Snow(this.view, this.seconds);

  final SceneView view;
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(5);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 70; i++) {
      final speed = 18 + r.nextDouble() * 30, x0 = r.nextDouble() * 1000, y0 = r.nextDouble() * 1000;
      final y = (y0 + seconds * speed) % 1040 - 20;
      final x = x0 + 14 * math.sin(seconds * 0.8 + i);
      canvas.drawCircle(view.toScreen(Offset(x, y)), (2 + r.nextDouble() * 3.5) * view.scale + 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(_Snow old) => old.seconds != seconds;
}
