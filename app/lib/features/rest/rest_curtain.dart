import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/play_time.dart';
import '../../core/providers.dart';
import '../parent/parent_gate.dart';

/// Ends the day's play gently, over every screen.
///
/// - A few minutes before the limit the pigeon says it is nearly time.
/// - When time is up in the middle of a picture (coloring it, sending it),
///   the pigeon says so, and the rest screen waits until the picture is
///   done. Only far past the limit does it come anyway; the picture waits
///   underneath, nothing is lost.
/// - The rest screen: the pigeon asleep, how many pictures were finished
///   today, "see you tomorrow". Behind the parent gate a grown-up can add
///   time. The next day starts afresh.
class RestCurtain extends ConsumerStatefulWidget {
  const RestCurtain({super.key, required this.router, required this.child});

  final GoRouter router;
  final Widget child;

  /// Screens where a picture is being made: the rest screen waits.
  static bool busy(String path) => path.startsWith('/canvas') || path.startsWith('/send') || path.startsWith('/sent');

  @override
  ConsumerState<RestCurtain> createState() => _RestCurtainState();
}

class _RestCurtainState extends ConsumerState<RestCurtain> {
  String _path = '/';
  String? _bubble;
  Timer? _bubbleTimer;
  var _warned = false, _toldWhenDone = false;
  var _asking = false, _unlocked = false;
  var _resting = false;
  int _finishedToday = 0;

  @override
  void initState() {
    super.initState();
    _path = _currentPath;
    widget.router.routerDelegate.addListener(_routeChanged);
  }

  /// The page on top. The configuration's own uri leaves out pages that
  /// were pushed (the canvas is pushed from the town), so look at the last.
  String get _currentPath {
    final config = widget.router.routerDelegate.currentConfiguration;
    final top = config.matches.isEmpty ? null : config.matches.last;
    return top is ImperativeRouteMatch ? top.matches.uri.path : config.uri.path;
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_routeChanged);
    _bubbleTimer?.cancel();
    super.dispose();
  }

  // The router can announce a new page while it builds: look after the frame.
  void _routeChanged() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentPath == _path) return;
        setState(() => _path = _currentPath);
        _check(ref.read(playTimeProvider));
      });

  void _say(String text) {
    _bubbleTimer?.cancel();
    setState(() => _bubble = text);
    ref.read(voiceProvider).say(text);
    _bubbleTimer = Timer(const Duration(seconds: 7), () {
      if (mounted) setState(() => _bubble = null);
    });
  }

  bool _shows(PlayTime? play) =>
      play != null && play.over && !_asking && !_path.startsWith('/parent') && (!RestCurtain.busy(_path) || play.wayOver);

  void _check(PlayTime? play) {
    if (play == null) return;
    final left = play.left;
    if (left == null || left > PlayTime.warnBefore) _warned = false; // a parent gave more time
    if (!play.over) {
      _toldWhenDone = false;
      if (_resting) setState(() => _resting = _unlocked = false);
    }
    if (play.almostOver && !_warned) {
      _warned = true;
      _say(Strings.almostRest);
    } else if (play.over && RestCurtain.busy(_path) && !play.wayOver && !_toldWhenDone) {
      _toldWhenDone = true;
      _say(Strings.restWhenDone);
    }
    final shows = _shows(play);
    if (shows && !_resting) _startResting();
    if (!shows && _resting && !_asking) setState(() => _resting = false);
  }

  Future<void> _startResting() async {
    _bubbleTimer?.cancel();
    setState(() {
      _resting = true;
      _bubble = null;
    });
    final now = ref.read(clockProvider)();
    final finished = await ref.read(artworkRepositoryProvider).finishedSince(DateTime(now.year, now.month, now.day));
    if (!mounted) return;
    setState(() => _finishedToday = finished);
    ref.read(voiceProvider).say('${Strings.restTitle(finished)}${Strings.restBody}');
  }

  Future<void> _askParent() async {
    final context = widget.router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;
    // The gate is a page under this curtain: step aside while it shows.
    setState(() => _asking = true);
    final ok = await showParentGate(context);
    if (!mounted) return;
    setState(() {
      _asking = false;
      _unlocked = ok;
    });
  }

  Future<void> _extend(int minutes) async {
    await ref.read(playTimeProvider.notifier).extend(minutes);
    if (mounted) setState(() => _unlocked = false);
  }

  void _toParentMode() {
    setState(() => _unlocked = false);
    widget.router.push('/parent');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playTimeProvider, (_, play) => _check(play));
    final play = ref.watch(playTimeProvider);
    final resting = _resting && _shows(play);
    return Stack(fit: StackFit.expand, children: [
      widget.child,
      if (_bubble != null && !resting)
        Positioned(
          top: MediaQuery.paddingOf(context).top + 10,
          left: 16,
          right: 16,
          child: Center(child: PopIn(key: ValueKey(_bubble), child: _PigeonSays(_bubble!))),
        ),
      if (resting)
        Overlay.wrap(
          child: _RestScreen(
            finished: _finishedToday,
            unlocked: _unlocked,
            onAskParent: _askParent,
            onTenMore: () => _extend(10),
            onNoLimit: () => _extend(24 * 60),
            onParentMode: _toParentMode,
          ),
        ),
    ]);
  }
}

/// The pigeon with a word bubble, at the top of the screen.
class _PigeonSays extends StatelessWidget {
  const _PigeonSays(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const ArtSvg(Art.pigeon, size: 58),
          const SizedBox(width: 6),
          Flexible(child: VoiceBubble(text, fontSize: 18, maxWidth: 320)),
        ]),
      );
}

class _RestScreen extends StatelessWidget {
  const _RestScreen({
    required this.finished,
    required this.unlocked,
    required this.onAskParent,
    required this.onTenMore,
    required this.onNoLimit,
    required this.onParentMode,
  });

  final int finished;
  final bool unlocked;
  final VoidCallback onAskParent;
  final VoidCallback onTenMore;
  final VoidCallback onNoLimit;
  final VoidCallback onParentMode;

  @override
  Widget build(BuildContext context) {
    final white = Theme.of(context).textTheme.headlineSmall!.copyWith(color: Colors.white, fontWeight: FontWeight.w800);
    return Material(
      key: const ValueKey('rest-screen'),
      // Soaks up every tap: the screens underneath wait for tomorrow.
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [KidColors.night, Color(0xFF5B4BC4), Color(0xFF8E7BE0)],
          ),
        ),
        child: SafeArea(
          child: Stack(children: [
            const Positioned.fill(child: _Stars()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Breathing(child: ArtSvg(Art.pigeonAsleep, size: 150)),
                    ),
                    const Positioned(right: -6, top: -4, child: _Zzz()),
                  ]),
                  const SizedBox(height: 26),
                  Text(Strings.restTitle(finished), style: white, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  Text(
                    Strings.restBody,
                    style: white.copyWith(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.92)),
                    textAlign: TextAlign.center,
                  ),
                  if (unlocked) ...[
                    const SizedBox(height: 28),
                    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                      FilledButton(onPressed: onTenMore, child: const Text(Strings.tenMoreMinutes)),
                      FilledButton.tonal(onPressed: onNoLimit, child: const Text(Strings.noLimitToday)),
                      TextButton(
                        onPressed: onParentMode,
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        child: const Text(Strings.parentMode),
                      ),
                    ]),
                  ],
                ]),
              ),
            ),
            if (!unlocked)
              Positioned(
                right: 14,
                bottom: 14,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(Strings.restForParents, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                  const SizedBox(width: 8),
                  ParentLockButton(onPressed: onAskParent),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Little stars that twinkle slowly.
class _Stars extends StatefulWidget {
  const _Stars();

  @override
  State<_Stars> createState() => _StarsState();
}

class _StarsState extends State<_Stars> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _StarsPainter(_c));
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(7);
    final paint = Paint()..color = Colors.white;
    for (var i = 0; i < 28; i++) {
      final at = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height * 0.7);
      final phase = r.nextDouble();
      paint.color = Colors.white.withValues(alpha: 0.35 + 0.5 * (0.5 + 0.5 * math.sin(2 * math.pi * (t.value + phase))));
      canvas.drawCircle(at, 1.5 + 2 * r.nextDouble(), paint);
    }
    // The moon.
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.12), 30, Paint()..color = KidColors.sun);
    canvas.drawCircle(Offset(size.width * 0.18 + 14, size.height * 0.12 - 8), 26, Paint()..color = KidColors.night);
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}

/// "Z z z", drifting up.
class _Zzz extends StatefulWidget {
  const _Zzz();

  @override
  State<_Zzz> createState() => _ZzzState();
}

class _ZzzState extends State<_Zzz> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => SizedBox(
          width: 70,
          height: 80,
          child: Stack(children: [
            for (var i = 0; i < 3; i++)
              Builder(builder: (context) {
                final v = (_c.value + i / 3) % 1;
                return Positioned(
                  left: 8.0 + 18 * i + 6 * math.sin(v * math.pi * 2),
                  bottom: 70 * v,
                  child: Opacity(
                    opacity: math.sin(v * math.pi),
                    child: Text('Z', style: TextStyle(color: Colors.white, fontSize: 16.0 + 6 * i, fontWeight: FontWeight.w800)),
                  ),
                );
              }),
          ]),
        ),
      );
}
