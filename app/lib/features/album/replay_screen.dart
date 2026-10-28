import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/celebration.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/artwork_service.dart';
import '../../core/db/database.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../canvas/coloring.dart';
import '../canvas/page_image.dart';

/// A picture colored again before the child's eyes (0.17): every fill,
/// stroke and stamp in the order they made them, a few seconds in all.
/// When a parent wrote on its back what the child said, it turns over and
/// the words are read out (0.18).
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key, required this.artworkId});

  final int artworkId;

  /// How long a replay takes: longer for a busier page, within limits.
  static Duration lengthOf(int steps) => Duration(milliseconds: (steps * 12).clamp(3000, 10000));

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  LoadedPage? _page;
  Place? _place;

  /// Turned over (or turning) to its back.
  bool _back = false;
  Replay? _replay;
  ui.Image? _lines;
  ui.Image? _colors;
  bool _refreshing = false, _dirty = false, _finished = false;
  Duration _lastSound = Duration.zero;

  void _sound(Sfx sfx) => ref.read(soundsProvider).play(sfx);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final page = await ref.read(artworkServiceProvider).load(widget.artworkId);
    final lines = await grayToImage(page.lines, page.document.width, page.document.height);
    final place = await ref.read(placeRepositoryProvider).get(page.artwork.placeId);
    if (!mounted) {
      lines.dispose();
      return;
    }
    setState(() {
      _page = page;
      _lines = lines;
      _place = place;
    });
    _start();
  }

  /// Over to the back, where the words are read out; and back again.
  void _turn() {
    final note = _page?.artwork.note;
    if (note == null) return;
    _sound(Sfx.swish);
    setState(() => _back = !_back);
    if (_back) {
      _flip.forward();
      ref.read(voiceProvider).say(note);
    } else {
      _flip.reverse();
    }
  }

  void _start() {
    final page = _page!;
    final doc = page.document;
    // A fresh sheet: the same lines and pictures, nothing colored yet.
    _replay = Replay(doc.ops, ColoringDocument(doc.regions, [], doc.pictures));
    _finished = false;
    _lastSound = Duration.zero;
    _refresh();
    _ticker
      ..stop()
      ..start();
  }

  void _tick(Duration elapsed) {
    final replay = _replay;
    if (replay == null) return;
    final length = ReplayScreen.lengthOf(replay.total);
    final steps = (replay.total * elapsed.inMicroseconds / length.inMicroseconds).ceil();
    final started = replay.playTo(math.min(steps, replay.total));
    // A sound as things begin, but not a clatter.
    if (started.isNotEmpty && elapsed - _lastSound > const Duration(milliseconds: 260)) {
      _lastSound = elapsed;
      _sound(switch (started.last) {
        FillOp() || PaperOp() => Sfx.fill,
        StampOp() || PictureOp() => Sfx.stamp,
        CrayonOp() => Sfx.swish,
      });
    }
    if (started.isNotEmpty || replay.finished) _refresh();
    if (replay.finished) {
      _ticker.stop();
      setState(() => _finished = true);
      _sound(Sfx.tada);
    }
  }

  /// Uploads the color layer; one upload at a time.
  Future<void> _refresh() async {
    final doc = _replay?.target;
    if (doc == null) return;
    if (_refreshing) {
      _dirty = true;
      return;
    }
    _refreshing = true;
    do {
      _dirty = false;
      final image = await rgbaToImage(Uint8List.fromList(doc.rgba), doc.width, doc.height);
      if (!mounted) {
        image.dispose();
        return;
      }
      final old = _colors;
      setState(() => _colors = image);
      old?.dispose();
    } while (_dirty);
    _refreshing = false;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _flip.dispose();
    _lines?.dispose();
    _colors?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final lines = _lines;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            child: Column(children: [
              Row(children: [
                NavButton(
                  icon: 'album',
                  label: Strings.backToAlbum,
                  color: KidColors.skyDark,
                  onPressed: () => context.canPop() ? context.pop() : context.go('/album'),
                ),
                const Spacer(),
                if (page?.artwork.note != null)
                  NavButton(
                    key: const ValueKey('flip'),
                    icon: 'flip',
                    label: _back ? Strings.flipBack : Strings.flip,
                    color: KidColors.coralDark,
                    onPressed: _turn,
                  ),
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: page == null || lines == null
                    ? const Center(child: BouncingDots())
                    : LayoutBuilder(builder: (context, box) {
                        final doc = page.document;
                        final scale = math.min((box.maxWidth - 40) / doc.width, (box.maxHeight - 40) / doc.height);
                        final size = Size(doc.width * scale, doc.height * scale);
                        final front = PostcardFrame(
                          tilt: -1,
                          child: SizedBox(
                            key: const ValueKey('replay-page'),
                            width: size.width,
                            height: size.height,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CustomPaint(painter: PagePainter(colors: _colors, lines: lines)),
                            ),
                          ),
                        );
                        final note = page.artwork.note;
                        return Center(
                          child: Stack(clipBehavior: Clip.none, children: [
                            if (note == null)
                              front
                            else
                              AnimatedBuilder(
                                animation: _flip,
                                builder: (context, _) {
                                  final angle = math.pi * Curves.easeInOut.transform(_flip.value);
                                  final back = angle > math.pi / 2;
                                  return Transform(
                                    alignment: Alignment.center,
                                    transform: Matrix4.identity()
                                      ..setEntry(3, 2, 0.0012)
                                      ..rotateY(back ? angle - math.pi : angle),
                                    child: back
                                        ? PostcardBack(
                                            note: note,
                                            size: size,
                                            sent: page.artwork.sentAt ?? page.artwork.updatedAt,
                                            place: _place,
                                            avatar: ref.watch(currentChildProvider).value?.avatar ?? animals.first,
                                          )
                                        : front,
                                  );
                                },
                              ),
                            if (_finished && !_back) const Positioned.fill(child: IgnorePointer(child: Confetti())),
                          ]),
                        );
                      }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: _finished
                    ? PopIn(
                        child: ChunkyButton(
                          key: const ValueKey('replay-again'),
                          label: Strings.watchAgain,
                          onPressed: _start,
                          color: KidColors.sky,
                          edge: KidColors.skyDark,
                          width: 200,
                          child: const KidIcon('play', size: 40, color: Colors.white, solid: true),
                        ),
                      )
                    : Center(
                        child: SizedBox(
                          width: 220,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _replay?.progress ?? 0,
                              minHeight: 12,
                              color: KidColors.sun,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The back of a postcard (0.18): what the child said, as a parent wrote
/// it down, beside the stamp, the postmark and where it was sent.
class PostcardBack extends StatelessWidget {
  const PostcardBack({super.key, required this.note, required this.size, required this.sent, required this.avatar, this.place});

  final String note;
  final Size size;
  final DateTime sent;
  final String avatar;
  final Place? place;

  @override
  Widget build(BuildContext context) {
    final kind = place == null ? null : PlaceKind.byName(place!.kind);
    final where = place?.label ?? kind?.label;
    final u = size.shortestSide / 100; // card units
    final wide = size.width >= size.height;
    final words = Padding(
      padding: EdgeInsets.all(5 * u),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(note,
            key: const ValueKey('postcard-note'),
            style: TextStyle(fontSize: 7.5 * u, height: 1.7, fontWeight: FontWeight.w700, color: KidColors.ink)),
      ),
    );
    final address = Padding(
      padding: EdgeInsets.all(4 * u),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Postmark(shortDate(sent).replaceAll('/', '.'), size: 16 * u),
          PhotoStamp(width: 22 * u, height: 26 * u, tilt: 4, child: AnimalArt(avatar, size: 15 * u)),
        ]),
        const Spacer(),
        if (where != null) ...[
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (kind != null) ArtSvg(Art.place(kind), size: 9 * u),
            SizedBox(width: 2 * u),
            Flexible(
              child: Text(Strings.sentTo(where),
                  overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 6 * u, fontWeight: FontWeight.w700, color: KidColors.inkSoft)),
            ),
          ]),
          SizedBox(height: 2 * u),
        ],
        Container(height: 0.6 * u, color: const Color(0xFFE3D5BE)),
        SizedBox(height: 5 * u),
        Container(height: 0.6 * u, color: const Color(0xFFE3D5BE)),
      ]),
    );
    return Container(
      width: size.width + 24,
      height: size.height + 24,
      decoration: BoxDecoration(color: const Color(0xFFFFFCF5), borderRadius: BorderRadius.circular(22), boxShadow: KidShadows.soft()),
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: words),
              Container(width: 0.6 * u, margin: EdgeInsets.symmetric(vertical: 6 * u), color: const Color(0xFFE3D5BE)),
              Expanded(child: address),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 3, child: address),
              Container(height: 0.6 * u, margin: EdgeInsets.symmetric(horizontal: 6 * u), color: const Color(0xFFE3D5BE)),
              Expanded(flex: 4, child: words),
            ]),
    );
  }
}
