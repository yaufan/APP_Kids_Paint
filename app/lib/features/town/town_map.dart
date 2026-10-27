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
import 'town_layout_data.dart';

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

/// The grass at the bottom edge of the land layer, for what comes below it.
const _grass = {DayPhase.day: Color(0xFFA6DE97), DayPhase.dusk: Color(0xFFACBC80), DayPhase.night: Color(0xFF3D6381)};

/// The child's town: drawn layers (sky, scenery, one building or empty lot
/// per kind of place, a festival's decorations) with the child's postcards
/// pinned on top. Every layer is drawn for day, dusk and night. Pans with a
/// finger; phones first see the middle column, wide screens see more.
class TownMap extends StatefulWidget {
  const TownMap({
    super.key,
    required this.spots,
    required this.thumbnailOf,
    required this.avatar,
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

  /// The child's animal, walking near home.
  final String avatar;
  final ValueChanged<PlaceKind>? onPin;
  final ValueChanged<PlaceKind>? onLot;

  /// The zoo or the aquarium was tapped: go inside.
  final ValueChanged<PlaceKind>? onAttraction;

  /// A place that was just built: it grows out of its lot.
  final PlaceKind? grow;

  /// A place to scroll to and bounce (a postcard just arrived there).
  final PlaceKind? focus;
  final DayPhase phase;

  /// Decorations up (and fireworks over 101 on New Year's Eve).
  final Festival? festival;
  final bool interactive;

  /// Screen points covered at the bottom (the buttons): the map goes on
  /// below its last row in grass, so that row can scroll up clear of them.
  final double bottomInset;

  /// How many world points a screen of [width] shows across.
  static double scaleFor(Size viewport) {
    final across = viewport.width.clamp(390.0, townSize.width);
    return math.max(viewport.width / across, viewport.height / townSize.height);
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
    super.dispose();
  }

  /// Home, the zoo and the aquarium are always there; other places once a postcard arrives.
  bool _built(PlaceKind kind) =>
      kind == PlaceKind.home || townAttractions.containsKey(kind.name) || widget.spots.containsKey(kind);

  void _place(Size viewport, double s) {
    if (_laidOutFor == viewport) return;
    _laidOutFor = viewport;
    final map = townSize * s + Offset(0, widget.bottomInset);
    var tx = (viewport.width - map.width) / 2;
    // Wide screens show little height: start at the mountains, not the sky.
    var ty = viewport.width > viewport.height ? -170 * s : 0.0;
    final focus = widget.focus ?? widget.grow;
    if (focus != null) {
      final pin = townSlots[focus.name]!.pin * s;
      tx = viewport.width / 2 - pin.dx;
      ty = viewport.height * 0.45 - pin.dy;
    }
    tx = tx.clamp(math.min(0.0, viewport.width - map.width), 0.0);
    ty = ty.clamp(math.min(0.0, viewport.height - map.height), 0.0);
    _view.value = Matrix4.translationValues(tx, ty, 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final viewport = box.biggest;
      final s = TownMap.scaleFor(viewport);
      _place(viewport, s);
      final size = townSize * s;

      final layers = <Widget>[_layer('sky'), _layer('land')];
      for (final name in townLayerOrder) {
        final kind = PlaceKind.byName(name);
        final slot = townSlots[name]!;
        if (_built(kind)) {
          if (kind == widget.grow && slot.lot != null) {
            final center = slot.lot!.center * s;
            layers.add(Positioned.fill(
              child: FadeTransition(
                opacity: ReverseAnimation(CurvedAnimation(parent: _grow, curve: const Interval(0, 0.4))),
                child: _svg('${name}_lot'),
              ),
            ));
            layers.add(Positioned.fill(
              child: AnimatedBuilder(
                animation: _grow,
                builder: (context, child) => Opacity(
                  opacity: Curves.easeOut.transform((_grow.value / 0.3).clamp(0.0, 1.0)),
                  child: Transform.scale(
                    scale: 0.2 + 0.8 * Curves.elasticOut.transform(_grow.value),
                    alignment: Alignment(center.dx / size.width * 2 - 1, center.dy / size.height * 2 - 1),
                    child: child,
                  ),
                ),
                child: _svg(name),
              ),
            ));
          } else {
            layers.add(_layer(name));
          }
        } else if (slot.lot != null) {
          layers.add(_layer('${name}_lot'));
        }
      }
      layers.add(_layer('traffic'));
      final festival = widget.festival;
      if (festival != null && townFestivalLayers.contains(festival.name)) layers.add(_layer('festival_${festival.name}'));
      final night = widget.phase == DayPhase.night;

      final lots = [
        for (final MapEntry(key: name, value: slot) in townSlots.entries)
          if (slot.lot != null && !_built(PlaceKind.byName(name)))
            Positioned.fromRect(
              rect: Rect.fromLTWH(slot.lot!.left * s, slot.lot!.top * s, slot.lot!.width * s, slot.lot!.height * s),
              child: Semantics(
                button: true,
                label: '${PlaceKind.byName(name).label}，還沒畫過',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onLot == null ? null : () => widget.onLot!(PlaceKind.byName(name)),
                ),
              ),
            ),
      ];

      final attractions = [
        for (final MapEntry(key: name, value: rect) in townAttractions.entries)
          Positioned.fromRect(
            rect: Rect.fromLTWH(rect.left * s, rect.top * s, rect.width * s, rect.height * s),
            child: Semantics(
              button: true,
              label: Strings.enter(_door(PlaceKind.byName(name))),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onAttraction == null ? null : () => widget.onAttraction!(PlaceKind.byName(name)),
              ),
            ),
          ),
      ];

      final home = townSlots['home']!.pin;
      final pins = [
        for (final spot in widget.spots.values)
          _Pin(
            key: ValueKey('pin-${spot.kind.name}'),
            spot: spot,
            image: FileImage(widget.thumbnailOf(spot.latest)),
            at: townSlots[spot.kind.name]!.pin * s,
            bounce: spot.kind == widget.focus,
            onTap: widget.onPin == null ? null : () => widget.onPin!(spot.kind),
          ),
      ];

      final map = SizedBox.fromSize(
        size: size,
        child: Stack(clipBehavior: Clip.none, children: [
          ...layers,
          ...lots,
          ...attractions,
          _Walker(life: _life, at: Offset((home.dx + 64) * s, (home.dy + 88) * s), avatar: widget.avatar),
          // Gugu sleeps on the MRT viaduct at night, away from every pin.
          if (night)
            _SleepingPigeon(life: _life, perch: Offset((townColumnLeft + 24) * s, 318 * s))
          else
            _FlyingPigeon(life: _life, mapWidth: size.width, y: 96 * s),
          if (festival == Festival.newYearsEve && widget.phase != DayPhase.day) _Fireworks(at: townTowerTop * s),
          ...pins,
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
                  Container(width: size.width, height: widget.bottomInset, color: _grass[widget.phase]),
                ]),
      );
    });
  }

  /// What a place you can go into is called on its door (the night market
  /// is where 好吃的店 postcards go).
  static String _door(PlaceKind kind) => Habitat.of(kind)?.label ?? kind.label;

  Widget _svg(String name) => ExcludeSemantics(child: SvgPicture.asset(Art.town(name, widget.phase), fit: BoxFit.fill));

  Widget _layer(String name) => Positioned.fill(child: _svg(name));
}

/// A postcard pinned at its place: the newest picture, how many there are,
/// and a glow if one arrived today.
class _Pin extends StatefulWidget {
  const _Pin({super.key, required this.spot, required this.image, required this.at, this.bounce = false, this.onTap});

  final TownSpot spot;
  final ImageProvider image;
  final Offset at;
  final bool bounce;
  final VoidCallback? onTap;

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
    final size = today ? 72.0 : 58.0;
    const tip = 12.0;
    final ring = today ? KidColors.sun : Colors.white;
    return Positioned(
      left: widget.at.dx - size / 2 - 40,
      top: widget.at.dy - size - tip - 20,
      width: size + 80,
      height: size + tip + 40,
      child: Semantics(
        button: true,
        label: Strings.pinLabel(widget.spot.kind.label, widget.spot.count),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
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

/// The child's own animal, hopping on the sidewalk by home.
class _Walker extends StatelessWidget {
  const _Walker({required this.life, required this.at, required this.avatar});

  final Animation<double> life;
  final Offset at;
  final String avatar;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: life,
      builder: (context, child) {
        final t = life.value * 2 * math.pi * 16;
        return Positioned(
          left: at.dx - 24,
          top: at.dy - 48 - 5 * math.sin(t).abs(),
          child: Transform.rotate(angle: 0.07 * math.sin(t), child: child),
        );
      },
      child: AnimalArt(avatar, size: 48),
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
  const _SleepingPigeon({required this.life, required this.perch});

  final Animation<double> life;

  /// Where Gugu's feet are.
  final Offset perch;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: perch.dx - 22,
      top: perch.dy - 70,
      width: 70,
      height: 72,
      child: Stack(clipBehavior: Clip.none, children: [
        const Positioned(left: 0, top: 28, child: ArtSvg(Art.pigeonAsleep, size: 44)),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: life,
            builder: (context, _) => CustomPaint(painter: _ZzzPainter((life.value * 8) % 1)),
          ),
        ),
      ]),
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
  const _Fireworks({required this.at});

  final Offset at;

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
        child: AnimatedBuilder(animation: _c, builder: (context, _) => CustomPaint(painter: _FireworksPainter(_c.value))),
      ),
    );
  }
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.t);

  final double t;

  static const _bursts = [
    (x: 0.5, y: 0.32, color: Color(0xFFFFCF3F), start: 0.0),
    (x: 0.26, y: 0.44, color: Color(0xFFFF8FB1), start: 0.33),
    (x: 0.74, y: 0.4, color: Color(0xFF6FC3FF), start: 0.66),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _bursts) {
      final p = (t - b.start) % 1 / 0.45; // each burst lives for 45% of the loop
      if (p > 1) continue;
      final center = Offset(b.x * size.width, b.y * size.height);
      final r = size.width * 0.2 * Curves.easeOutCubic.transform(p);
      final paint = Paint()..color = b.color.withValues(alpha: (1 - p) * 0.95);
      for (var k = 0; k < 12; k++) {
        final a = k * math.pi / 6;
        canvas.drawCircle(center + Offset(math.cos(a), math.sin(a)) * r, 3.2 * (1 - p * 0.5), paint);
        canvas.drawLine(center + Offset(math.cos(a), math.sin(a)) * r * 0.55, center + Offset(math.cos(a), math.sin(a)) * r * 0.85,
            paint..strokeWidth = 2);
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter old) => old.t != t;
}
