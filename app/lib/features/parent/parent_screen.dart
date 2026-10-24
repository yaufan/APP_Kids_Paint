import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/strings.dart';
import '../../core/providers.dart';
import '../../core/repositories.dart';

/// Parent mode (behind the parent gate): children, time limit, privacy, data.
class ParentScreen extends ConsumerStatefulWidget {
  const ParentScreen({super.key});

  @override
  ConsumerState<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends ConsumerState<ParentScreen> {
  int? _minutes;

  @override
  void initState() {
    super.initState();
    ref.read(settingsRepositoryProvider).dailyMinutes().then((m) {
      if (mounted) setState(() => _minutes = m);
    });
  }

  Future<void> _addChild(List<String> used) async {
    final free = avatars.where((a) => !used.contains(a)).toList();
    if (free.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final a in free)
              TextButton(
                onPressed: () => Navigator.of(sheet).pop(a),
                child: Text(a, style: const TextStyle(fontSize: 48)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await ref.read(childRepositoryProvider).add(picked);
  }

  Future<void> _deleteAll() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text(Strings.deleteAll),
        content: const Text(Strings.deleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: const Text(Strings.cancel),
          ),
          FilledButton(
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
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(Strings.deleted)));
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(childrenProvider).value ?? const [];
    final minutes = _minutes;
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.parentMode)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  title: const Text(Strings.children),
                  subtitle: Text(
                    children.map((c) => c.avatar).join('  '),
                    style: const TextStyle(fontSize: 32),
                  ),
                  trailing: IconButton(
                    tooltip: Strings.addChild,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    onPressed: () =>
                        _addChild([for (final c in children) c.avatar]),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text(Strings.dailyLimit),
                  subtitle: minutes == null
                      ? null
                      : Slider(
                          value: minutes.toDouble(),
                          min: 10,
                          max: 60,
                          divisions: 10,
                          label: Strings.minutes(minutes),
                          onChanged: (v) =>
                              setState(() => _minutes = v.round()),
                          onChangeEnd: (v) => ref
                              .read(settingsRepositoryProvider)
                              .setDailyMinutes(v.round()),
                        ),
                  trailing: minutes == null
                      ? null
                      : Text(Strings.minutes(minutes)),
                ),
              ),
              const Card(
                child: ListTile(
                  title: Text(Strings.privacy),
                  subtitle: Text(Strings.privacyBody),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text(Strings.licenses),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: Strings.appName,
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text(
                    Strings.deleteAll,
                    style: TextStyle(color: Colors.red),
                  ),
                  leading: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                  ),
                  onTap: _deleteAll,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
