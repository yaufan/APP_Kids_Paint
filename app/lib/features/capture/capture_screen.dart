import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/places.dart';
import '../../core/providers.dart';

/// Take a photo or pick one from the album (usually with a parent's help),
/// or photograph a drawing made on paper (0.18).
class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  /// Photos are scaled down on capture; pages are only 1024 px anyway and
  /// full-size photos are slow to decode on low-end phones.
  static const maxPhotoSide = 1600.0;

  Future<void> _pick(BuildContext context, ImageSource source, {bool paper = false}) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: maxPhotoSide,
      maxHeight: maxPhotoSide,
      imageQuality: 90,
    );
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    if (context.mounted) context.push(paper ? '/paper' : '/styles', extra: bytes);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(currentChildProvider).value?.avatar ?? animals.first;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth > box.maxHeight;
            final size = ((wide ? box.maxHeight : box.maxWidth) * 0.42).clamp(150.0, 240.0);
            final paper = PopIn(
              delay: const Duration(milliseconds: 240),
              child: ChunkyButton(
                key: const ValueKey('paper-photo'),
                label: Strings.paperPhoto,
                onPressed: () => _pick(context, ImageSource.camera, paper: true),
                color: KidColors.sun,
                edge: const Color(0xFFE0A91C),
                width: size * 0.9,
                height: size * 0.42,
                radius: size * 0.21,
                depth: 7,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  KidIcon('crayon', size: size * 0.2, color: Colors.white),
                  SizedBox(width: size * 0.06),
                  KidIcon('camera', size: size * 0.2, color: Colors.white),
                ]),
              ),
            );
            final buttons = [
              PopIn(
                child: Breathing(
                  child: ChunkyButton(
                    label: Strings.camera,
                    onPressed: () => _pick(context, ImageSource.camera),
                    color: KidColors.coral,
                    edge: KidColors.coralDark,
                    width: size,
                    height: size,
                    radius: size * 0.3,
                    depth: 9,
                    child: KidIcon('camera', size: size * 0.5, color: Colors.white),
                  ),
                ),
              ),
              SizedBox.square(dimension: size * 0.16),
              PopIn(
                delay: const Duration(milliseconds: 120),
                child: ChunkyButton(
                  label: Strings.photoLibrary,
                  onPressed: () => _pick(context, ImageSource.gallery),
                  color: Colors.white,
                  edge: const Color(0xFFD8E6F5),
                  width: size,
                  height: size,
                  radius: size * 0.3,
                  depth: 9,
                  child: ArtSvg(Art.miniAlbum, size: size * 0.62),
                ),
              ),
            ];
            return Stack(children: [
              Center(
                child: wide
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Row(mainAxisSize: MainAxisSize.min, children: buttons),
                        SizedBox(height: size * 0.12),
                        paper,
                      ])
                    : Column(mainAxisSize: MainAxisSize.min, children: [...buttons, SizedBox(height: size * 0.16), paper]),
              ),
              Positioned(left: 14, top: 12, child: NavButton(icon: 'map', label: Strings.backToMap, color: KidColors.grassDark, onPressed: () => context.go('/'))),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  AnimalArt(avatar, size: 78),
                  const SizedBox(width: 8),
                  const Flexible(child: Padding(padding: EdgeInsets.only(bottom: 30), child: VoiceBubble(Strings.captureHint))),
                ]),
              ),
            ]);
          }),
        ),
      ),
    );
  }
}
