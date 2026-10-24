import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/art.dart';
import '../../app/scene.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';

/// Take a photo or pick one from the album (usually with a parent's help).
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  /// Photos are scaled down on capture; pages are only 1024 px anyway and
  /// full-size photos are slow to decode on low-end phones.
  static const maxPhotoSide = 1600.0;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: maxPhotoSide,
      maxHeight: maxPhotoSide,
      imageQuality: 90,
    );
    if (file == null || !context.mounted) return;
    final bytes = await file.readAsBytes();
    if (context.mounted) context.push('/styles', extra: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            final unit = math.min(box.maxWidth, box.maxHeight);
            final size = (unit * 0.42).clamp(140.0, 240.0);
            return Stack(
              children: [
                Center(
                  child: Wrap(
                    spacing: unit * 0.1,
                    runSpacing: unit * 0.1,
                    alignment: WrapAlignment.center,
                    children: [
                      PopIn(
                        child: ToyButton(
                          art: Art.camera,
                          label: Strings.camera,
                          tint: KidColors.berry,
                          size: size,
                          breathing: true,
                          onPressed: () => _pick(context, ImageSource.camera),
                        ),
                      ),
                      PopIn(
                        delay: const Duration(milliseconds: 120),
                        child: ToyButton(
                          art: Art.gallery,
                          label: Strings.album,
                          tint: KidColors.sky,
                          size: size,
                          onPressed: () => _pick(context, ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(left: 16, top: 12, child: HomeButton(onPressed: () => context.go('/'))),
                Positioned(
                  right: unit * 0.06,
                  bottom: unit * 0.05,
                  child: Transform.rotate(angle: 0.25, child: ArtImage(Art.sparkles, size: unit * 0.16)),
                ),
                Positioned(
                  left: unit * 0.07,
                  bottom: unit * 0.1,
                  child: Transform.rotate(angle: -0.3, child: ArtImage(Art.crayon, size: unit * 0.14)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
