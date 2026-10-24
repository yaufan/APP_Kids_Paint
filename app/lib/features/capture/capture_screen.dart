import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Wrap(
                spacing: 48,
                runSpacing: 48,
                alignment: WrapAlignment.center,
                children: [
                  KidButton(
                    icon: Icons.photo_camera_rounded,
                    label: Strings.camera,
                    color: KidTheme.berry,
                    size: KidTheme.bigButton * 1.3,
                    onPressed: () => _pick(context, ImageSource.camera),
                  ),
                  KidButton(
                    icon: Icons.photo_library_rounded,
                    label: Strings.album,
                    color: KidTheme.sky,
                    size: KidTheme.bigButton * 1.3,
                    onPressed: () => _pick(context, ImageSource.gallery),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: KidButton(
                icon: Icons.home_rounded,
                label: Strings.home,
                color: KidTheme.sun,
                size: KidTheme.toolButton,
                onPressed: () => context.go('/'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
