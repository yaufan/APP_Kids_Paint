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
import '../../core/providers.dart';
import '../../core/sounds.dart';
import '../canvas/coloring.dart';
import '../canvas/page_image.dart';

/// A picture colored again before the child's eyes (0.17): every fill,
/// stroke and stamp in the order they made them, a few seconds in all.
class ReplayScreen extends ConsumerStatefulWidget {
  const ReplayScreen({super.key, required this.artworkId});

  final int artworkId;

  /// How long a replay takes: longer for a busier page, within limits.
  static Duration lengthOf(int steps) => Duration(milliseconds: (steps * 12).clamp(3000, 10000));

  @override
  ConsumerState<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends ConsumerState<ReplayScreen> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  LoadedPage? _page;
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
    if (!mounted) {
      lines.dispose();
      return;
    }
    setState(() {
      _page = page;
      _lines = lines;
    });
    _start();
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
              ]),
              const SizedBox(height: 10),
              Expanded(
                child: page == null || lines == null
                    ? const Center(child: BouncingDots())
                    : LayoutBuilder(builder: (context, box) {
                        final doc = page.document;
                        final scale = math.min((box.maxWidth - 40) / doc.width, (box.maxHeight - 40) / doc.height);
                        return Center(
                          child: Stack(clipBehavior: Clip.none, children: [
                            PostcardFrame(
                              tilt: -1,
                              child: SizedBox(
                                key: const ValueKey('replay-page'),
                                width: doc.width * scale,
                                height: doc.height * scale,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CustomPaint(painter: PagePainter(colors: _colors, lines: lines)),
                                ),
                              ),
                            ),
                            if (_finished) const Positioned.fill(child: IgnorePointer(child: Confetti())),
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
