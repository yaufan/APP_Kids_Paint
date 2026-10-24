import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/mascot.dart';
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
                      KidButton(
                        icon: Icons.photo_camera_rounded,
                        label: Strings.camera,
                        color: KidColors.berry,
                        shape: StickerShape.rounded,
                        size: size,
                        breathing: true,
                        onPressed: () => _pick(context, ImageSource.camera),
                      ),
                      KidButton(
                        icon: Icons.photo_library_rounded,
                        label: Strings.album,
                        color: KidColors.sky,
                        shape: StickerShape.rounded,
                        size: size,
                        onPressed: () => _pick(context, ImageSource.gallery),
                      ),
                    ],
                  ),
                ),
                Positioned(left: 16, top: 12, child: HomeButton(onPressed: () => context.go('/'))),
                Positioned(
                  right: unit * 0.05,
                  bottom: unit * 0.04,
                  child: CrayonBuddy(height: (unit * 0.26).clamp(90.0, 160.0), color: KidColors.lavender),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
