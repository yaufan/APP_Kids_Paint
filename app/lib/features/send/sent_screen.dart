import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/celebration.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/db/database.dart';
import '../../core/places.dart';
import '../../core/providers.dart';
import '../canvas/artwork_stamp.dart';

/// "Sent!": the postcard gets its postmark, confetti flies and Gugu takes it
/// to the map. Goes back to the town by itself.
class SentScreen extends ConsumerStatefulWidget {
  const SentScreen({super.key, required this.artworkId, required this.kind, this.isNew = false});

  final int artworkId;
  final PlaceKind kind;
  final bool isNew;

  static const stay = Duration(milliseconds: 2600);

  @override
  ConsumerState<SentScreen> createState() => _SentScreenState();
}

class _SentScreenState extends ConsumerState<SentScreen> with SingleTickerProviderStateMixin {
  late final Future<Artwork> _artwork = ref.read(artworkRepositoryProvider).get(widget.artworkId);
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  Timer? _auto;

  String get _town => '/?focus=${widget.kind.name}${widget.isNew ? '&grow=${widget.kind.name}' : ''}';

  @override
  void initState() {
    super.initState();
    _auto = Timer(SentScreen.stay, () {
      if (mounted) context.go(_town);
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _go(String route) {
    _auto?.cancel();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(artworkStoreProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 1.0,
            colors: [Color(0xFFFFF0BE), Color(0xFFDDF2FF), Color(0xFFA6DE97)],
            stops: [0, 0.6, 1],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<Artwork>(
            future: _artwork,
            builder: (context, snap) {
              final art = snap.data;
              return Stack(children: [
                const Positioned.fill(child: Confetti()),
                if (art != null)
                  Center(
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, child) => Transform.scale(scale: 0.6 + 0.4 * Curves.elasticOut.transform(_c.value), child: child),
                      child: SizedBox(
                        width: 300,
                        height: 320,
                        child: Stack(clipBehavior: Clip.none, children: [
                          Positioned(
                            left: 20,
                            top: 30,
                            child: PostcardFrame(
                              tilt: -9,
                              padding: 10,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(store.open(art.folder).thumbnail, width: 230, height: 214, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                          Positioned(right: -6, top: 10, child: ArtworkStamp(artwork: art, width: 62, height: 74)),
                          Positioned(left: -14, bottom: 0, child: _SentStamp(date: art.sentAt ?? DateTime.now())),
                        ]),
                      ),
                    ),
                  ),
                const Positioned(right: 16, top: 40, child: ArtSvg(Art.pigeonFlying, size: 118)),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 20,
                  child: Center(child: VoiceBubble(widget.isNew ? Strings.newPlace(widget.kind.label) : Strings.sent, fontSize: 19)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 36,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    ChunkyButton(
                      label: Strings.backToTown,
                      onPressed: () => _go(_town),
                      circle: true,
                      width: 86,
                      height: 86,
                      edge: const Color(0xFFDCD3C3),
                      child: const KidIcon('map', size: 40, color: KidColors.grassDark),
                    ),
                    const SizedBox(width: 22),
                    ChunkyButton(
                      label: Strings.drawAgain,
                      onPressed: () => _go('/capture'),
                      circle: true,
                      width: 104,
                      height: 104,
                      color: KidColors.coral,
                      edge: KidColors.coralDark,
                      child: const KidIcon('camera', size: 48, color: Colors.white),
                    ),
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

class _SentStamp extends StatelessWidget {
  const _SentStamp({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: -0.28,
        child: Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: KidColors.coralDark.withValues(alpha: 0.9), width: 5),
          ),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(Strings.sentStamp,
                style: TextStyle(color: KidColors.coralDark, fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: 2, height: 1.1)),
            Text('${date.year}.${date.month}.${date.day}', style: const TextStyle(color: KidColors.coralDark, fontSize: 13)),
          ]),
        ),
      );
}
