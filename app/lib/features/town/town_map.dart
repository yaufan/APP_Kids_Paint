import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../core/creatures.dart';
import '../../core/db/database.dart';
import '../../core/festivals.dart';
import '../../core/places.dart';
import '../../core/repositories.dart';
import '../../core/town_time.dart';
import 'island_layout_data.dart';

/// What the map shows at one kind of place: how many postcards, the newest.
class TownSpot {
  const TownSpot({required this.kind, required this.count, required this.latest, required this.today});

  final PlaceKind kind;
  final int count;
  final Artwork latest;

  /// Sent in the last 24 hours: the pin glows.
  final bool today;
}

/// Groups postcards (newest first) by kind of place.
Map<PlaceKind, TownSpot> townSpots(List<Postcard> postcards, DateTime now) {
  final counts = <PlaceKind, int>{};
  final latest = <PlaceKind, Artwork>{};
  for (final p in postcards) {
    final kind = PlaceKind.byName(p.place.kind);
    counts[kind] = (counts[kind] ?? 0) + 1;
    latest.putIfAbsent(kind, () => p.artwork);
  }
  return {
    for (final kind in counts.keys)
      kind: TownSpot(
        kind: kind,
        count: counts[kind]!,
        latest: latest[kind]!,
        today: now.difference(latest[kind]!.sentAt ?? latest[kind]!.updatedAt).inHours < 24,
      ),
  };
}

/// The sea below the world, where the map goes on under the buttons.
const _sea = {DayPhase.day: Color(0xFF4DB6F0), DayPhase.dusk: Color(0xFF5F7FC4), DayPhase.night: Color(0xFF27508F)};

/// Islands in the order they are drawn, back to front.
final _islandOrder = islands.keys.toList();

/// How far [island] floats up or down (world units) at [t], 0 to 1 through
/// the map's 24-second loop: each island slowly, a little out of step with
/// its neighbours. Off the islands (the sea, the sky), nothing moves.
double islandBob(String? island, double t) {
  if (island == null) return 0;
  return 3.5 * math.sin(2 * math.pi * 3 * t + _islandOrder.indexOf(island) * 1.9);
}

/// The island a kind of place is on.
String islandOf(PlaceKind kind) => islandPins[kind.name]?.island ?? kind.name;

/// The child's town as floating islands (2.0): a sky from the stars down to
/// the sea, one island per kind of place joined by bridges, a festival's
/// decorations, and the child's postcards pinned on top. Every picture is
/// drawn for day, dusk and night. The islands float gently; the map pans
/// with a finger and first shows home.
class TownMap extends StatefulWidget {
  const TownMap({
    super.key,
    required this.spots,
    required this.thumbnailOf,
    required this.avatar,
    this.townies = const {},
    this.onTownie,
    this.onToy,
    this.onPin,
    this.onLot,
    this.onAttraction,
    this.grow,
    this.focus,
    this.phase = DayPhase.day,
    this.festival,
    this.interactive = true,
    this.bottomInset = 0,
  });

  final Map<PlaceKind, TownSpot> spots;
  final File Function(Artwork artwork) thumbnailOf;

  /// The child's animal, walking on the home island.
  final String avatar;

  /// The child's own pictures cut out, hopping on their place's island.
  final Map<PlaceKind, List<File>> townies;

  /// One of them was tapped (it jumps).
  final ValueChanged<PlaceKind>? onTownie;

  /// Something was poked: what it is ('train', 'duck', 'boat', 'balloon',
  /// 'tower', 'cloud'; [islandToys]).
  final ValueChanged<String>? onToy;
  final ValueChanged<PlaceKind>? onPin;

  /// An island nobody has sent a postcard to yet was tapped.
  final ValueChanged<PlaceKind>? onLot;

  /// An island you can go into was tapped: go inside.
  final ValueChanged<PlaceKind>? onAttraction;

  /// A place that was just built: it grows on its island.
  final PlaceKind? grow;

  /// A place to scroll to and bounce (a postcard just arrived there).
  final PlaceKind? focus;
  final DayPhase phase;

  /// Decorations up (and fireworks over 101 on New Year's Eve).
  final Festival? festival;
  final bool interactive;

  /// Screen points covered at the bottom (the buttons): the map goes on
  /// below its last row in sea, so that row can scroll up clear of them.
  final double bottomInset;

  /// How many world points a screen of [viewport] shows across.
  static double scaleFor(Size viewport) {
    final across = viewport.width.clamp(390.0, islandWorld.width);
    return math.max(viewport.width / across, viewport.height / islandWorld.height);
  }

  @override
  State<TownMap> createState() => _TownMapState();
}

class _TownMapState extends State<TownMap> with TickerProviderStateMixin {
  final _view = TransformationController();
  Size? _laidOutFor;
  late final AnimationController _life =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  late final AnimationController _grow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  /// One per toy, made when it is first poked or drawn.
  final _toys = <String, AnimationController>{};

  AnimationController _toy(String name) => _toys.putIfAbsent(
      name, () => AnimationController(vsync: this, duration: _ToyMotion.lengthOf(islandToys[name]!.kind)));

  void _poke(String name) {
    final toy = _toy(name);
    // The train, the boat and the balloon are away: let them come back first.
    if (toy.isAnimating && {'train', 'boat', 'balloon'}.contains(islandToys[name]!.kind)) return;
    toy.forward(from: 0);
    widget.onToy?.call(islandToys[name]!.kind);
  }

  @override
  void initState() {
    super.initState();
    if (widget.grow != null) _grow.forward();
  }

  @override
  void dispose() {
    _view.dispose();
    _life.dispose();
    _grow.dispose();
    for (final toy in _toys.values) {
      toy.dispose();
    }
    super.dispose();
  }

  /// Islands that grow are bare until a postcard arrives; the rest are always there.
  bool _built(String island) => !islands[island]!.grows || widget.spots.containsKey(PlaceKind.byName(island));

  void _place(Size viewport, double s) {
    if (_laidOutFor == viewport) return;
    _laidOutFor = viewport;
    final map = islandWorld * s + Offset(0, widget.bottomInset);
    // Home, or where a postcard just arrived, a little above the middle.
    final at = islandPins[(widget.focus ?? widget.grow ?? PlaceKind.home).name]!.pin * s;
    var tx = viewport.width / 2 - at.dx;
    var ty = viewport.height * 0.42 - at.dy;
    tx = tx.clamp(math.min(0.0, viewport.width - map.width), 0.0);
    ty = ty.clamp(math.min(0.0, viewport.height - map.height), 0.0);
    _view.value = Matrix4.translationValues(tx, ty, 0);
  }

  /// [child] floating with [island] (or still, off the islands).
  Widget _afloat(String? island, double s, Widget child) => island == null
      ? child
      : AnimatedBuilder(
          animation: _life,
          builder: (context, child) => Transform.translate(offset: Offset(0, islandBob(island, _life.value) * s), child: child),
          child: child,
        );

  Rect _scaled(Rect r, double s) => Rect.fromLTWH(r.left * s, r.top * s, r.width * s, r.height * s);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final viewport = box.biggest;
      final s = TownMap.scaleFor(viewport);
      _place(viewport, s);
      final size = islandWorld * s;

      // The toys standing on [island] (null: the sea and the sky), each with its own picture.
      Iterable<Widget> toys(String? island) => [
            for (final MapEntry(key: name, value: toy) in islandToys.entries)
              if (toy.on == island && toy.art != null)
                _ToySprite(
                  key: ValueKey('toy-$name'),
                  kind: toy.kind,
                  art: toy.art!,
                  scale: s,
                  poked: _toy(name),
                  float: island == null ? null : (_life, island),
                  child: _svg('toy_$name'),
                ),
          ];

      final layers = <Widget>[_layer('sky'), _layer('bridges')];
      for (final MapEntry(key: name, value: island) in islands.entries) {
        final kind = PlaceKind.byName(name);
        final rect = _scaled(island.box, s);
        if (!_built(name)) {
          layers.add(Positioned.fromRect(rect: rect, child: _afloat(name, s, _svg('island_${name}_lot'))));
        } else if (kind == widget.grow && island.grows) {
          // The bare island, and the place growing on it.
          final base = (island.folks.first + island.folks.last) / 2 - island.box.topLeft;
          layers.add(Positioned.fromRect(
            rect: rect,
            child: _afloat(
              name,
              s,
              Stack(fit: StackFit.expand, children: [
                FadeTransition(
                  opacity: ReverseAnimation(CurvedAnimation(parent: _grow, curve: const Interval(0.2, 0.5))),
                  child: _svg('island_${name}_lot'),
                ),
                AnimatedBuilder(
                  animation: _grow,
                  builder: (context, child) => Opacity(
                    opacity: Curves.easeOut.transform((_grow.value / 0.3).clamp(0.0, 1.0)),
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * Curves.elasticOut.transform(_grow.value),
                      alignment: Alignment(base.dx / island.box.width * 2 - 1, base.dy / island.box.height * 2 - 1),
                      child: child,
                    ),
                  ),
                  child: _svg('island_$name'),
                ),
              ]),
            ),
          ));
        } else {
          layers.add(Positioned.fromRect(rect: rect, child: _afloat(name, s, _svg('island_$name'))));
        }
        layers.addAll(toys(name));
      }
      layers.addAll(toys(null));
      final festival = widget.festival;
      if (festival != null && islandFestivalLayers.contains(festival.name)) layers.add(_layer('festival_${festival.name}'));
      final night = widget.phase == DayPhase.night;

      // One tap target per island: go in, see its postcards, or hear that nothing is here yet.
      final taps = [
        for (final MapEntry(key: name, value: island) in islands.entries) _islandTap(name, island, s),
      ];

      // Toys that are there (the park's ducks once the park is built).
      bool there(String? island) => island == null || _built(island);
      final pokes = [
        for (final MapEntry(key: name, value: toy) in islandToys.entries)
          if (there(toy.on))
            Positioned.fromRect(
              rect: _scaled(toy.tap, s),
              child: _afloat(
                toy.on,
                s,
                Semantics(
                  button: true,
                  label: Strings.toy(toy.kind),
                  child: GestureDetector(
                    key: ValueKey('poke-$name'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.interactive ? () => _poke(name) : null,
                  ),
                ),
              ),
            ),
      ];
      // What poking the tower and the clouds starts.
      final effects = [
        for (final MapEntry(key: name, value: toy) in islandToys.entries)
          if (toy.kind == 'tower')
            _PokedFireworks(at: islandTowerTop * s, poked: _toy(name), float: (_life, toy.on), scale: s)
          else if (toy.kind == 'cloud')
            _Rain(under: _scaled(toy.tap, s), poked: _toy(name)),
      ];

      final townies = [
        for (final MapEntry(key: kind, value: files) in widget.townies.entries)
          for (final (i, file) in files.indexed)
            _Townie(
              key: ValueKey('townie-${kind.name}-$i'),
              life: _life,
              island: islandOf(kind),
              at: islands[islandOf(kind)]!.folks[i % islands[islandOf(kind)]!.folks.length] * s,
              scale: s,
              image: FileImage(file),
              phase: i * 1.7 + kind.index,
              label: Strings.townFolk(kind.label),
              onTap: widget.onTownie == null ? null : () => widget.onTownie!(kind),
            ),
      ];
      // A pin takes taps a little around it too, but under the toys.
      final margins = [
        for (final spot in widget.spots.values)
          if (islandPins.containsKey(spot.kind.name))
            Positioned.fromRect(
              rect: _Pin.boxOf(spot, islandPins[spot.kind.name]!.pin * s),
              child: _afloat(
                islandOf(spot.kind),
                s,
                ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onPin == null ? null : () => widget.onPin!(spot.kind),
                  ),
                ),
              ),
            ),
      ];
      final pins = [
        for (final spot in widget.spots.values)
          if (islandPins.containsKey(spot.kind.name))
            _Pin(
              key: ValueKey('pin-${spot.kind.name}'),
              spot: spot,
              image: FileImage(widget.thumbnailOf(spot.latest)),
              at: islandPins[spot.kind.name]!.pin * s,
              float: (_life, islandOf(spot.kind), s),
              bounce: spot.kind == widget.focus,
              onTap: widget.onPin == null ? null : () => widget.onPin!(spot.kind),
            ),
      ];

      final map = SizedBox.fromSize(
        size: size,
        child: Stack(clipBehavior: Clip.none, children: [
          ...layers,
          ...taps,
          ...margins,
          ...pokes,
          ...effects,
          _Walker(life: _life, at: islandWalker * s, scale: s, avatar: widget.avatar),
          // Gugu sleeps on the home island at night.
          if (night)
            _SleepingPigeon(life: _life, perch: islandPerch * s, scale: s)
          else
            _FlyingPigeon(life: _life, mapWidth: size.width, y: 548 * s),
          if (festival == Festival.newYearsEve && widget.phase != DayPhase.day) _Fireworks(at: islandTowerTop * s, life: _life, scale: s),
          ...pins,
          // Over the pins' wide tap areas, so a tap reaches them.
          ...townies,
        ]),
      );

      return InteractiveViewer(
          transformationController: _view,
          constrained: false,
          scaleEnabled: false,
          panEnabled: widget.interactive,
          child: widget.bottomInset == 0
              ? map
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  map,
                  Container(width: size.width, height: widget.bottomInset, color: _sea[widget.phase]),
                ]),
      );
    });
  }

  /// Tapping an island: inside if it has a place to go into, its postcards
  /// if it has some, else a word that nothing has been sent there yet.
  Widget _islandTap(String name, ({Rect box, Rect tap, String? enter, List<Offset> folks, bool grows}) island, double s) {
    final kind = PlaceKind.byName(name);
    final String? label;
    final VoidCallback? onTap;
    if (island.enter case final enter?) {
      label = Strings.enter(_door(PlaceKind.byName(enter)));
      onTap = widget.onAttraction == null ? null : () => widget.onAttraction!(PlaceKind.byName(enter));
    } else if (!_built(name)) {
      label = '${kind.label}，還沒畫過';
      onTap = widget.onLot == null ? null : () => widget.onLot!(kind);
    } else if (widget.spots.containsKey(kind)) {
      label = null; // its pin says it
      onTap = widget.onPin == null ? null : () => widget.onPin!(kind);
    } else {
      label = null;
      onTap = null;
    }
    return Positioned.fromRect(
      rect: _scaled(island.tap, s),
      child: _afloat(
        name,
        s,
        Semantics(
          button: label != null,
          label: label,
          child: GestureDetector(key: ValueKey('island-$name'), behavior: HitTestBehavior.opaque, onTap: onTap),
        ),
      ),
    );
  }

  /// What a place you can go into is called on its door (the night market
  /// is where 好吃的店 postcards go).
  static String _door(PlaceKind kind) => Habitat.of(kind)?.label ?? kind.label;

  Widget _svg(String name) => ExcludeSemantics(child: SvgPicture.asset(Art.island(name, widget.phase), fit: BoxFit.fill));

  Widget _layer(String name) => Positioned.fill(child: _svg(name));
}

/// A postcard pinned at its place: the newest picture, how many there are,
/// and a glow if one arrived today.
class _Pin extends StatefulWidget {
  const _Pin({super.key, required this.spot, required this.image, required this.at, required this.float, this.bounce = false, this.onTap});

  final TownSpot spot;
  final ImageProvider image;
  final Offset at;

  /// The map's loop, the island it is on and the map's scale: it floats with the island.
  final (Animation<double>, String, double) float;
  final bool bounce;
  final VoidCallback? onTap;

  static double sizeOf(TownSpot spot) => spot.today ? 72.0 : 58.0;
  static const tip = 12.0;

  /// Where a pin with its tip at [at] takes taps: the pin and around it.
  static Rect boxOf(TownSpot spot, Offset at) {
    final size = sizeOf(spot);
    return Rect.fromLTWH(at.dx - size / 2 - 40, at.dy - size - tip - 20, size + 80, size + tip + 40);
  }

  @override
  State<_Pin> createState() => _PinState();
}

class _PinState extends State<_Pin> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    if (widget.spot.today) {
      _c.repeat();
    } else if (widget.bounce) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = widget.spot.today;
    final size = _Pin.sizeOf(widget.spot);
    const tip = _Pin.tip;
    final ring = today ? KidColors.sun : Colors.white;
    final (life, island, scale) = widget.float;
    return Positioned.fromRect(
      rect: _Pin.boxOf(widget.spot, widget.at),
      // The whole pin floats with its island: the picture, its glow, where it takes taps.
      child: AnimatedBuilder(
        animation: life,
        builder: (context, child) => Transform.translate(offset: Offset(0, islandBob(island, life.value) * scale), child: child),
        child: Semantics(
          button: true,
          label: Strings.pinLabel(widget.spot.kind.label, widget.spot.count),
          excludeSemantics: true,
          child: GestureDetector(
            // Only the pin itself: around it, a tap first reaches what is
            // there (a duck, a car) and the pin's margin under them.
            behavior: HitTestBehavior.deferToChild,
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final drop = widget.bounce ? -36 * (1 - Curves.bounceOut.transform(_c.value)) : 0.0;
                return Stack(clipBehavior: Clip.none, children: [
                  if (today)
                    for (final phase in [0.0, 0.5])
                      Positioned(
                        left: 40 + size / 2 - 30,
                        top: 20 + size + tip - 16,
                        child: Transform.scale(
                          scale: 0.6 + ((_c.value + phase) % 1) * 1.2,
                          child: Opacity(
                            opacity: (1 - (_c.value + phase) % 1) * 0.7,
                            child: Container(
                              width: 60,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: KidColors.sun, width: 4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  Positioned(
                    left: 40 + size / 2 - 12,
                    top: 20 + size + tip - 5,
                    child: Container(
                      width: 24,
                      height: 9,
                      decoration: BoxDecoration(color: const Color(0x381E3C28), borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                  Positioned(left: 40, top: 20 + drop, child: child!),
                ]);
              },
              child: SizedBox(
                width: size,
                height: size + tip,
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                    left: size / 2 - 9,
                    top: size - 1,
                    child: CustomPaint(size: Size(18, tip + 1), painter: _TipPainter(ring)),
                  ),
                  Container(
                    width: size,
                    height: size,
                    padding: EdgeInsets.all(today ? 6 : 5),
                    decoration: BoxDecoration(
                      color: ring,
                      borderRadius: BorderRadius.circular(size * 0.3),
                      boxShadow: KidShadows.soft(),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(size * 0.3 - 5),
                      child: Image(image: widget.image, fit: BoxFit.cover, gaplessPlayback: true),
                    ),
                  ),
                  if (today)
                    Positioned(
                      right: -11,
                      top: -11,
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: KidColors.coral,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const KidIcon('star', size: 16, color: Colors.white, solid: true),
                      ),
                    )
                  else if (widget.spot.count > 1)
                    Positioned(
                      right: -9,
                      top: -9,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 26),
                        height: 26,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: KidColors.coral,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Text('${widget.spot.count}',
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, height: 1)),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TipPainter extends CustomPainter {
  _TipPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TipPainter old) => old.color != color;
}

/// The child's own animal, hopping on the home island.
class _Walker extends StatelessWidget {
  const _Walker({required this.life, required this.at, required this.scale, required this.avatar});

  final Animation<double> life;
  final Offset at;
  final double scale;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: life,
      builder: (context, child) {
        final t = life.value * 2 * math.pi * 16;
        return Positioned(
          left: at.dx - 24,
          top: at.dy - 48 - 5 * math.sin(t).abs() + islandBob('home', life.value) * scale,
          child: Transform.rotate(angle: 0.07 * math.sin(t), child: child),
        );
      },
      child: AnimalArt(avatar, size: 48),
    );
  }
}

/// One of the child's own pictures, cut out, hopping on its place's island
/// (0.17). Tapped, it jumps.
class _Townie extends StatefulWidget {
  const _Townie({
    super.key,
    required this.life,
    required this.island,
    required this.at,
    required this.scale,
    required this.image,
    required this.phase,
    required this.label,
    this.onTap,
  });

  final Animation<double> life;
  final String island;
  final double scale;

  /// Where its feet are.
  final Offset at;
  final ImageProvider image;

  /// So two side by side do not hop together.
  final double phase;
  final String label;
  final VoidCallback? onTap;

  @override
  State<_Townie> createState() => _TownieState();
}

class _TownieState extends State<_Townie> with SingleTickerProviderStateMixin {
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void dispose() {
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    return AnimatedBuilder(
      animation: Listenable.merge([widget.life, _jump]),
      builder: (context, child) {
        final t = widget.life.value * 2 * math.pi * 14 + widget.phase;
        final hop = 4 * math.sin(t).abs() + 34 * math.sin(math.pi * _jump.value);
        return Positioned(
          left: widget.at.dx - size / 2 + 5 * math.sin(t / 5),
          top: widget.at.dy - size - hop + islandBob(widget.island, widget.life.value) * widget.scale,
          width: size,
          height: size,
          child: Transform.rotate(angle: 0.08 * math.sin(t) + 2 * math.pi * Curves.easeInOut.transform(_jump.value), child: child),
        );
      },
      child: Semantics(
        button: true,
        label: widget.label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _jump.forward(from: 0);
            widget.onTap?.call();
          },
          child: Image(image: widget.image, fit: BoxFit.contain, alignment: Alignment.bottomCenter, gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink()),
        ),
      ),
    );
  }
}

/// Gugu the mail pigeon, gliding across the sky.
class _FlyingPigeon extends StatelessWidget {
  const _FlyingPigeon({required this.life, required this.mapWidth, required this.y});

  final Animation<double> life;
  final double mapWidth;
  final double y;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: life,
      builder: (context, child) => Positioned(
        left: -90 + (mapWidth + 180) * life.value,
        top: y + 10 * math.sin(life.value * 2 * math.pi * 6),
        child: child!,
      ),
      child: const ArtSvg(Art.pigeonFlyingLetter, size: 70),
    );
  }
}

/// Gugu asleep, little z's floating up.
class _SleepingPigeon extends StatelessWidget {
  const _SleepingPigeon({required this.life, required this.perch, required this.scale});

  final Animation<double> life;
  final double scale;

  /// Where Gugu's feet are.
  final Offset perch;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: perch.dx - 22,
      top: perch.dy - 70,
      width: 70,
      height: 72,
      child: AnimatedBuilder(
        animation: life,
        builder: (context, child) => Transform.translate(offset: Offset(0, islandBob('home', life.value) * scale), child: child),
        child: Stack(clipBehavior: Clip.none, children: [
        const Positioned(left: 0, top: 28, child: ArtSvg(Art.pigeonAsleep, size: 44)),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: life,
            builder: (context, _) => CustomPaint(painter: _ZzzPainter((life.value * 8) % 1)),
          ),
        ),
      ]),
      ),
    );
  }
}

class _ZzzPainter extends CustomPainter {
  _ZzzPainter(this.t);

  /// 0..1 through one rise.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (var k = 0; k < 3; k++) {
      final p = (t + k / 3) % 1;
      final z = 5.0 + 3 * p;
      final origin = Offset(40 + 14 * p, 30 - 30 * p);
      final paint = Paint()
        ..color = const Color(0xFFFFF3C2).withValues(alpha: math.sin(p * math.pi))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        Path()
          ..moveTo(origin.dx - z, origin.dy - z)
          ..lineTo(origin.dx + z, origin.dy - z)
          ..lineTo(origin.dx - z, origin.dy + z)
          ..lineTo(origin.dx + z, origin.dy + z),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ZzzPainter old) => old.t != t;
}

/// New Year's Eve over 101: slow bursts, one at a time and never flashing
/// (well under three flashes a second, for children sensitive to light).
class _Fireworks extends StatefulWidget {
  const _Fireworks({required this.at, required this.life, required this.scale});

  final Offset at;
  final Animation<double> life;
  final double scale;

  @override
  State<_Fireworks> createState() => _FireworksState();
}

class _FireworksState extends State<_Fireworks> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const box = 240.0;
    return Positioned(
      left: widget.at.dx - box / 2,
      top: widget.at.dy - box * 0.8,
      width: box,
      height: box,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([_c, widget.life]),
          builder: (context, _) => Transform.translate(
            offset: Offset(0, islandBob('city', widget.life.value) * widget.scale),
            child: CustomPaint(painter: _FireworksPainter(_c.value)),
          ),
        ),
      ),
    );
  }
}

/// Fireworks over 101 when it is poked (0.18): its three bursts once,
/// bigger and bolder than New Year's Eve's (they go up in daylight too),
/// each shot up from the tower first.
class _PokedFireworks extends StatelessWidget {
  const _PokedFireworks({required this.at, required this.poked, required this.float, required this.scale});

  final Offset at;
  final Animation<double> poked;

  /// The map's loop and the island the tower is on.
  final (Animation<double>, String?) float;
  final double scale;

  @override
  Widget build(BuildContext context) {
    const box = 320.0;
    return Positioned(
      left: at.dx - box / 2,
      top: at.dy - box * 0.8,
      width: box,
      height: box,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([poked, float.$1]),
          builder: (context, _) => poked.value == 0 || poked.value == 1
              ? const SizedBox.shrink()
              : Transform.translate(
                  offset: Offset(0, islandBob(float.$2, float.$1.value) * scale),
                  child: CustomPaint(painter: _FireworksPainter(poked.value * _FireworksPainter.lengthOf(bold: true), repeat: false, bold: true)),
                ),
        ),
      ),
    );
  }
}

/// A little rain under a poked cloud (0.18): the cloud darkens, and drops fall.
class _Rain extends StatelessWidget {
  const _Rain({required this.under, required this.poked});

  /// The cloud.
  final Rect under;
  final Animation<double> poked;

  static const fall = 170.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: under.left - 10,
      top: under.top,
      width: under.width + 20,
      height: under.height + fall,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: poked,
          builder: (context, _) => poked.value == 0 || poked.value == 1
              ? const SizedBox.shrink()
              : CustomPaint(painter: _RainPainter(poked.value, cloud: under.height)),
        ),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.t, {required this.cloud});

  final double t;

  /// How tall the cloud is, at the top.
  final double cloud;

  @override
  void paint(Canvas canvas, Size size) {
    // The cloud goes grey-blue while it rains, and back.
    final dark = math.sin(math.pi * t).clamp(0.0, 1.0);
    final shade = Paint()..color = const Color(0xFF7D93AE).withValues(alpha: 0.6 * dark);
    final w = size.width, h = cloud;
    canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.35, w * 0.5, h * 0.6), shade);
    canvas.drawOval(Rect.fromLTWH(w * 0.32, h * 0.1, w * 0.45, h * 0.75), shade);
    canvas.drawOval(Rect.fromLTWH(w * 0.55, h * 0.35, w * 0.38, h * 0.55), shade);
    final paint = Paint()
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 34; i++) {
      // Drops start one after another and each falls in a third of the
      // time; where across has nothing to do with when, so no lines form.
      final start = (i * 11 % 34) / 34 * 0.62;
      final p = (t - start) / 0.34;
      if (p < 0 || p > 1) continue;
      final x = w * (0.14 + 0.72 * (i * 7 % 17) / 16);
      final y = h * 0.85 + (size.height - h) * p;
      paint.color = const Color(0xFF3D8BE0).withValues(alpha: 0.9 * (1 - p * 0.5));
      canvas.drawLine(Offset(x, y), Offset(x - 2, y + 14), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.t != t;
}

/// How long each kind of toy takes to do its thing.
abstract final class _ToyMotion {
  static Duration lengthOf(String kind) => switch (kind) {
        'train' => const Duration(milliseconds: 5200),
        'boat' => const Duration(milliseconds: 6400),
        'balloon' => const Duration(milliseconds: 4200),
        'duck' => const Duration(milliseconds: 1100),
        'tower' => const Duration(milliseconds: 5400),
        'cloud' => const Duration(milliseconds: 2600),
        _ => const Duration(milliseconds: 800), // cars, the bus, scooters
      };
}

/// A toy's own picture at its place, doing its thing when [poked] runs:
/// the train goes across its rail bridge to home and back, the boat sails
/// off and comes back round, the balloon rises and comes down, a duck bobs
/// and makes ripples.
class _ToySprite extends StatelessWidget {
  const _ToySprite({super.key, required this.kind, required this.art, required this.scale, required this.poked, this.float, required this.child});

  final String kind;

  /// Where the picture goes, in world points.
  final Rect art;
  final double scale;
  final Animation<double> poked;

  /// The map's loop and the island it stands on: it floats with it.
  final (Animation<double>, String)? float;
  final Widget child;

  /// Where along [islandRail] the train is, 0 (its stop) to 1 (home), as
  /// an offset from its stop.
  static Offset _alongRail(double u) {
    final n = islandRail.length - 1;
    final x = (u * n).clamp(0.0, n.toDouble());
    final i = x.floor().clamp(0, n - 1);
    return Offset.lerp(islandRail[i], islandRail[i + 1], x - i)! - islandRail.first;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: float == null ? poked : Listenable.merge([poked, float!.$1]),
      builder: (context, child) {
        final t = poked.value;
        var left = art.left;
        var lift = float == null ? 0.0 : -islandBob(float!.$2, float!.$1.value);
        var turn = 0.0;
        Widget picture = child!;
        switch (kind) {
          case 'train':
            // Across to home, a moment there, and back.
            final u = t < 0.45 ? Curves.easeInOutSine.transform(t / 0.45) : (t < 0.55 ? 1.0 : 1 - Curves.easeInOutSine.transform((t - 0.55) / 0.45));
            final d = _alongRail(u);
            left += d.dx;
            lift -= d.dy;
          case 'boat':
            // Off to the right, and in again from the left.
            final round = islandWorld.width + art.width;
            left += Curves.easeInOutSine.transform(t) * round;
            if (left > islandWorld.width) left -= round;
            turn = 0.05 * math.sin(math.pi * t * 6);
          case 'balloon':
            // Up into the sky and gently down again.
            lift += 90 * math.sin(math.pi * t);
            left += 14 * math.sin(math.pi * t * 2);
          case 'duck':
            lift += 5 * math.sin(math.pi * t * 3).abs() * (1 - t);
            turn = 0.35 * math.sin(math.pi * t * 4) * (1 - t);
            if (t > 0 && t < 1) {
              picture = Stack(fit: StackFit.expand, clipBehavior: Clip.none, children: [
                Positioned.fill(child: CustomPaint(painter: _RipplePainter(t))),
                picture,
              ]);
            }
          default:
            // Two little hops.
            lift += 8 * math.sin(math.pi * t * 2).abs() * (1 - 0.4 * t);
        }
        return Positioned(
          left: left * scale,
          top: (art.top - lift) * scale,
          width: art.width * scale,
          height: art.height * scale,
          child: turn == 0 ? picture : Transform.rotate(angle: turn, child: picture),
        );
      },
      child: child,
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.68);
    for (final delay in [0.0, 0.3]) {
      final p = ((t - delay) / 0.7).clamp(0.0, 1.0);
      if (p == 0) continue;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: size.width * (0.6 + 1.2 * p), height: size.height * (0.25 + 0.5 * p)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * (1 - p)),
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.t, {this.repeat = true, this.bold = false});

  final double t;

  /// Over and over (New Year's Eve), or each burst once (poked).
  final bool repeat;

  /// Bigger, with a white edge and shot up from the tower first (poked).
  final bool bold;

  /// How long a shot takes to go up, before its burst.
  static const _rise = 0.12;

  /// How far [t] goes for every burst to finish once.
  static double lengthOf({bool bold = false}) => (bold ? _rise : 0) + 0.66 + 0.45;

  static const _bursts = [
    (x: 0.5, y: 0.32, color: Color(0xFFFFCF3F), start: 0.0),
    (x: 0.26, y: 0.44, color: Color(0xFFFF8FB1), start: 0.33),
    (x: 0.74, y: 0.4, color: Color(0xFF6FC3FF), start: 0.66),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rays = bold ? 16 : 12;
    final dot = bold ? 5.5 : 3.2;
    for (final b in _bursts) {
      final start = b.start + (bold ? _rise : 0);
      final center = Offset(b.x * size.width, b.y * size.height);
      if (bold) {
        // The shot going up from the tower's tip (the box's bottom middle, 80% down).
        final q = (t - (start - _rise)) / _rise;
        if (q >= 0 && q < 1) {
          final from = Offset(size.width / 2, size.height * 0.8);
          final at = Offset.lerp(from, center, Curves.easeOut.transform(q))!;
          canvas.drawLine(Offset.lerp(from, at, 0.6)!, at, Paint()
            ..color = b.color.withValues(alpha: 0.7)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
          canvas.drawCircle(at, 4, Paint()..color = Colors.white);
        }
      }
      final p = (repeat ? (t - start) % 1 : t - start) / 0.45; // each burst lives for 45% of the loop
      if (p < 0 || p > 1) continue;
      final r = size.width * (bold ? 0.24 : 0.2) * Curves.easeOutCubic.transform(p);
      final paint = Paint()..color = b.color.withValues(alpha: (1 - p) * 0.95);
      final edge = Paint()..color = Colors.white.withValues(alpha: (1 - p) * 0.85);
      for (var k = 0; k < rays; k++) {
        final a = k * 2 * math.pi / rays;
        final out = Offset(math.cos(a), math.sin(a));
        final radius = dot * (1 - p * 0.5);
        if (bold) canvas.drawCircle(center + out * r, radius + 2, edge);
        canvas.drawCircle(center + out * r, radius, paint);
        canvas.drawLine(center + out * r * 0.55, center + out * r * 0.85, paint..strokeWidth = bold ? 3.5 : 2);
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.t != t || old.repeat != repeat || old.bold != bold;
}
