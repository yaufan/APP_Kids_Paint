import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/mascot.dart';
import '../../app/scene.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/providers.dart';
import '../parent/parent_gate.dart';

/// The child's start screen: a picture-book scene with big sticker buttons
/// and nothing to read. The camera is the main, gently pulsing action.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(currentChildProvider).value;
    return Scaffold(
      body: SceneBackground(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, box) {
            final landscape = box.maxWidth > box.maxHeight;
            final unit = math.min(box.maxWidth, box.maxHeight);
            final big = (unit * 0.46).clamp(150.0, 260.0);
            final small = (unit * 0.3).clamp(110.0, 170.0);

            final camera = KidButton(
              icon: Icons.photo_camera_rounded,
              label: Strings.takePhoto,
              color: KidColors.berry,
              size: big,
              breathing: true,
              onPressed: () => context.push('/capture'),
            );
            final gallery = KidButton(
              icon: Icons.collections_rounded,
              label: Strings.gallery,
              color: KidColors.sky,
              shape: StickerShape.rounded,
              size: small,
              onPressed: () => context.push('/gallery'),
            );
            final map = KidButton(
              icon: Icons.map_rounded,
              label: Strings.map,
              color: KidColors.grass,
              shape: StickerShape.rounded,
              size: small,
              onPressed: () => context.push('/map'),
            );

            final buttons = landscape
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    camera,
                    SizedBox(width: unit * 0.12),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      gallery,
                      SizedBox(height: unit * 0.06),
                      map,
                    ]),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    camera,
                    SizedBox(height: unit * 0.1),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      gallery,
                      SizedBox(width: unit * 0.1),
                      map,
                    ]),
                  ]);

            return Stack(
              children: [
                Align(alignment: const Alignment(0, -0.15), child: buttons),
                Positioned(
                  left: unit * 0.04,
                  bottom: box.maxHeight * 0.05,
                  child: CrayonBuddy(height: (unit * 0.32).clamp(110.0, 200.0)),
                ),
                if (child != null)
                  Positioned(left: 16, top: 12, child: _AvatarButton(avatar: child.avatar)),
                Positioned(
                  right: 4,
                  top: 4,
                  child: ParentCornerButton(onPressed: () async {
                    if (await showParentGate(context) && context.mounted) context.push('/parent');
                  }),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

/// The current child's animal; siblings tap it to switch to their own.
class _AvatarButton extends ConsumerWidget {
  const _AvatarButton({required this.avatar});

  final String avatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = ref.watch(childrenProvider).value ?? const [];
    return AvatarBadge(
      avatar: avatar,
      onTap: children.length < 2
          ? null
          : () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: KidColors.paper,
                builder: (sheet) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        for (final c in children)
                          AvatarBadge(
                            avatar: c.avatar,
                            size: 88,
                            onTap: () {
                              ref.read(currentChildIdProvider.notifier).select(c.id);
                              Navigator.of(sheet).pop();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
