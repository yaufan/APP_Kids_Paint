import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/providers.dart';
import '../canvas/page_image.dart';
import 'line_art.dart';

/// Both styles side by side; the child taps the one they like. No settings:
/// the detail level is a parent option and defaults to simple.
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
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<LineArt>>(
          future: _pages,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(Strings.convertFailed, style: Theme.of(context).textTheme.titleLarge));
            }
            final pages = snapshot.data;
            if (pages == null || _saving) {
              return const Center(child: SizedBox.square(dimension: 96, child: CircularProgressIndicator(strokeWidth: 10)));
            }
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Flex(
                direction: MediaQuery.of(context).size.aspectRatio > 1 ? Axis.horizontal : Axis.vertical,
                children: [
                  for (final style in ArtStyle.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _StyleCard(
                          label: style == ArtStyle.realistic ? Strings.realistic : Strings.cute,
                          color: style == ArtStyle.realistic ? KidTheme.sky : KidTheme.berry,
                          page: pages[style.index],
                          onTap: () => _choose(style, pages[style.index]),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
      floatingActionButton: KidButton(
        icon: Icons.home_rounded,
        label: Strings.home,
        color: KidTheme.sun,
        size: KidTheme.toolButton,
        onPressed: () => context.go('/'),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({required this.label, required this.color, required this.page, required this.onTap});

  final String label;
  final Color color;
  final LineArt page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: BorderSide(color: color, width: 8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(child: GrayPagePreview(gray: page.lines, width: page.width, height: page.height)),
          ),
        ),
      ),
    );
  }
}
