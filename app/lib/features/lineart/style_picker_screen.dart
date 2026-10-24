import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/scene.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/providers.dart';
import '../canvas/page_image.dart';
import 'line_art.dart';

/// Both styles side by side as two taped-up photos; the child taps the one
/// they like. No settings: detail is a parent option (default: simple).
class StylePickerScreen extends ConsumerStatefulWidget {
  const StylePickerScreen({super.key, required this.photo, this.detail = DetailLevel.simple});

  final Uint8List photo;
  final DetailLevel detail;

  @override
  ConsumerState<StylePickerScreen> createState() => _StylePickerScreenState();
}

class _StylePickerScreenState extends ConsumerState<StylePickerScreen> {
  late final Future<List<LineArt>> _pages;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final engine = ref.read(lineArtEngineProvider);
    _pages = Future.wait([
      for (final style in ArtStyle.values) engine.convert(widget.photo, style, widget.detail),
    ]);
  }

  Future<void> _choose(ArtStyle style, LineArt page) async {
    if (_saving) return;
    setState(() => _saving = true);
    final child = await ref.read(currentChildProvider.future);
    final artwork = await ref.read(artworkServiceProvider).saveNew(
          childId: child.id,
          photo: widget.photo,
          page: page,
          style: style,
          detail: widget.detail,
        );
    if (mounted) context.go('/canvas/${artwork.id}');
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(currentChildProvider).value?.avatar;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Stack(
            children: [
              FutureBuilder<List<LineArt>>(
                future: _pages,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(Strings.convertFailed, style: Theme.of(context).textTheme.titleLarge),
                    );
                  }
                  final pages = snapshot.data;
                  if (pages == null || _saving) {
                    // The child's animal "draws" while the page is being made.
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Stack(clipBehavior: Clip.none, children: [
                          if (avatar != null) ArtImage(Art.avatar(avatar), size: 150),
                          const Positioned(right: -40, bottom: -6, child: ArtImage(Art.crayon, size: 80)),
                        ]),
                        const SizedBox(height: 36),
                        const BouncingDots(),
                      ]),
                    );
                  }
                  final wide = MediaQuery.sizeOf(context).aspectRatio > 1;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 100, 28, 36),
                    child: Flex(
                      direction: wide ? Axis.horizontal : Axis.vertical,
                      children: [
                        for (final style in ArtStyle.values)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: PopIn(
                                delay: Duration(milliseconds: 140 * style.index),
                                child: _StyleCard(
                                  style: style,
                                  page: pages[style.index],
                                  onTap: () => _choose(style, pages[style.index]),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(left: 16, top: 12, child: HomeButton(onPressed: () => context.go('/'))),
            ],
          ),
        ),
      ),
    );
  }
}

/// One style as a tilted photo with a badge: a camera for the realistic
/// page, sparkles for the cute one.
class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.style, required this.page, required this.onTap});

  final ArtStyle style;
  final LineArt page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final realistic = style == ArtStyle.realistic;
    return Semantics(
      button: true,
      label: realistic ? Strings.realistic : Strings.cute,
      child: Pressable(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ToyCard(
                tilt: realistic ? -2.5 : 2.5,
                tape: realistic ? KidColors.sky : KidColors.berry,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Center(child: GrayPagePreview(gray: page.lines, width: page.width, height: page.height)),
              ),
            ),
            Positioned(
              left: -16,
              top: -16,
              child: ArtBadge(art: realistic ? Art.camera : Art.sparkles, size: 72),
            ),
          ],
        ),
      ),
    );
  }
}
