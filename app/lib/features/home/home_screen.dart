import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/scene.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/providers.dart';
import '../parent/parent_gate.dart';

/// The child's start screen: a picture-book world where the child's own
/// animal points at the camera. Three big toys, nothing to read.
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
            final big = (unit * 0.44).clamp(150.0, 250.0);
            final small = (unit * 0.28).clamp(108.0, 160.0);

            final camera = PopIn(
              child: ToyButton(
                art: Art.camera,
                label: Strings.takePhoto,
                tint: KidColors.berry,
                size: big,
                breathing: true,
                onPressed: () => context.push('/capture'),
              ),
            );
            final gallery = PopIn(
              delay: const Duration(milliseconds: 120),
              child: ToyButton(
                art: Art.gallery,
                label: Strings.gallery,
                tint: KidColors.sky,
                size: small,
                onPressed: () => context.push('/gallery'),
              ),
            );
            final map = PopIn(
              delay: const Duration(milliseconds: 220),
              child: ToyButton(
                art: Art.map,
                label: Strings.map,
                tint: KidColors.grass,
                size: small,
                onPressed: () => context.push('/map'),
              ),
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
                    SizedBox(height: unit * 0.09),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      gallery,
                      SizedBox(width: unit * 0.1),
                      map,
                    ]),
                  ]);

            return Stack(
              children: [
                Align(alignment: Alignment(0, landscape ? -0.1 : -0.22), child: buttons),
                if (child != null)
                  Positioned(
                    left: unit * 0.04,
                    bottom: box.maxHeight * 0.03,
                    child: _Guide(avatar: child.avatar, size: (unit * 0.3).clamp(110.0, 190.0)),
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

/// The child's own animal stands on the hill and "says" camera: the
/// character is the guide, no words needed.
class _Guide extends StatefulWidget {
  const _Guide({required this.avatar, required this.size});

  final String avatar;
  final double size;

  @override
  State<_Guide> createState() => _GuideState();
}

class _GuideState extends State<_Guide> with SingleTickerProviderStateMixin {
  late final AnimationController _bob =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: widget.size * 0.45),
            child: SpeechBubble(child: ArtImage(Art.camera, size: widget.size * 0.3)),
          ),
          AnimatedBuilder(
            animation: _bob,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -widget.size * 0.06 * Curves.easeInOut.transform(_bob.value)),
              child: Transform.rotate(angle: (_bob.value - 0.5) * 0.08, child: child),
            ),
            child: ArtImage(Art.avatar(widget.avatar), size: widget.size),
          ),
        ],
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
                            size: 96,
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
