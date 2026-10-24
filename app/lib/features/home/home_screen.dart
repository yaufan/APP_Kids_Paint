import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/providers.dart';
import '../parent/parent_gate.dart';

/// The child's start screen: three big picture buttons and nothing to read.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(currentChildProvider).value;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 40,
                runSpacing: 40,
                children: [
                  KidButton(
                    icon: Icons.photo_camera_rounded,
                    label: Strings.takePhoto,
                    color: KidTheme.berry,
                    size: KidTheme.bigButton * 1.4,
                    onPressed: () => context.push('/capture'),
                  ),
                  KidButton(
                    icon: Icons.collections_rounded,
                    label: Strings.gallery,
                    color: KidTheme.sky,
                    onPressed: () => context.push('/gallery'),
                  ),
                  KidButton(
                    icon: Icons.map_rounded,
                    label: Strings.map,
                    color: KidTheme.grass,
                    onPressed: () => context.push('/map'),
                  ),
                ],
              ),
            ),
            if (child != null)
              Positioned(
                left: 16,
                top: 8,
                child: _AvatarButton(avatar: child.avatar),
              ),
            Positioned(
              right: 4,
              top: 4,
              child: ParentCornerButton(onPressed: () async {
                if (await showParentGate(context) && context.mounted) context.push('/parent');
              }),
            ),
          ],
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
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: children.length < 2
          ? null
          : () => showModalBottomSheet<void>(
                context: context,
                builder: (sheet) => SafeArea(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (final c in children)
                        TextButton(
                          onPressed: () {
                            ref.read(currentChildIdProvider.notifier).select(c.id);
                            Navigator.of(sheet).pop();
                          },
                          child: Text(c.avatar, style: const TextStyle(fontSize: 64)),
                        ),
                    ],
                  ),
                ),
              ),
      child: Text(avatar, style: const TextStyle(fontSize: 56)),
    );
  }
}
