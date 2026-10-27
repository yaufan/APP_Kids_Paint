import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../core/providers.dart';

/// What the app keeps, what it uses, and how to delete it
/// (docs/safety-privacy.md).
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text(Strings.deleteAll),
        content: const Text(Strings.deleteAllConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(false), child: const Text(Strings.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KidColors.coralDark),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: const Text(Strings.delete),
          ),
        ],
      ),
    );
    if (sure != true) return;
    await ref.read(settingsRepositoryProvider).deleteEverything();
    await ref.read(artworkStoreProvider).deleteAll();
    ref.invalidate(currentChildProvider);
    ref.invalidate(welcomedProvider); // a fresh start: name the town again
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.deleted)));
    context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget none(String icon, String text) => Column(children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFFFF0EF), borderRadius: BorderRadius.circular(20)),
            child: Stack(alignment: Alignment.center, children: [
              KidIcon(icon, size: 26, color: KidColors.inkSoft),
              Transform.rotate(angle: -0.7, child: Container(width: 42, height: 4, color: KidColors.coralDark)),
            ]),
          ),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(fontSize: 13, color: KidColors.inkSoft)),
        ]);
    Widget perm(String icon, String name, String use, bool used) => Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: KidColors.line))),
          child: Row(children: [
            KidIcon(icon, size: 22, color: used ? KidColors.ink : KidColors.inkSoft),
            const SizedBox(width: 10),
            Text(name, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(use,
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: used ? KidColors.grassDark : KidColors.inkSoft)),
            ),
          ]),
        );
    BoxDecoration card() => BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0xFFECE7DD), offset: Offset(0, 2))],
        );

    return Scaffold(
      backgroundColor: KidColors.parentBg,
      appBar: AppBar(title: const Text(Strings.privacy, style: TextStyle(fontWeight: FontWeight.w700))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: card(),
              child: Column(children: [
                Row(children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: const Color(0xFFE3F6E6), borderRadius: BorderRadius.circular(22)),
                    child: const KidIcon('shield', size: 36, color: KidColors.grassDark),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(Strings.allOnPhone, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 3),
                      Text(Strings.allOnPhoneBody, style: TextStyle(fontSize: 14, color: KidColors.inkSoft)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  none('share', Strings.noUpload),
                  none('star', Strings.noAds),
                  none('users', Strings.noChat),
                  none('pin', Strings.noLocation),
                ]),
              ]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              decoration: card(),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text(Strings.permissions, style: TextStyle(fontSize: 14, color: KidColors.inkSoft)),
                perm('camera', Strings.permCamera, Strings.permCameraUse, true),
                perm('album', Strings.permPhotos, Strings.permPhotosUse, true),
                perm('pin', Strings.permLocation, Strings.notUsed, false),
                perm('sound', Strings.permMicrophone, Strings.notUsed, false),
                perm('share', Strings.permNetwork, Strings.notUsed, false),
              ]),
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const KidIcon('trash', size: 22, color: KidColors.coralDark),
                title: const Text(Strings.deleteAll, style: TextStyle(color: KidColors.coralDark)),
                trailing: const KidIcon('chevron', size: 20, color: Color(0xFFB9B2A4)),
                onTap: () => _deleteAll(context, ref),
              ),
            ),
            const SizedBox(height: 10),
            const Center(child: ArtSvg(Art.logo, size: 40)),
          ]),
        ),
      ),
    );
  }
}
