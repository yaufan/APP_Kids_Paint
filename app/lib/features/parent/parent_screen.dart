import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/version.dart';
import '../../core/db/database.dart';
import '../../core/places.dart';
import '../../core/providers.dart';

/// Parent mode (behind the parent gate): children, time limit, the town's
/// places, privacy and data.
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
    final free = animals.where((a) => !used.contains(a)).toList();
    if (free.isEmpty) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: KidColors.parentBg,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
            for (final a in free)
              Semantics(
                button: true,
                label: animalNames[a],
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.of(sheet).pop(a),
                  child: Container(
                    width: 84,
                    height: 84,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: AnimalArt(a, size: 64),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
    if (picked != null) await ref.read(childRepositoryProvider).add(picked);
  }

  Future<void> _rename(Place place) async {
    final controller = TextEditingController(text: place.label ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text(Strings.placeName),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: Strings.placeNameHint, prefixIcon: Padding(
            padding: const EdgeInsets.all(8),
            child: ArtSvg(Art.place(PlaceKind.byName(place.kind)), size: 28),
          )),
          onSubmitted: (v) => Navigator.of(dialog).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text(Strings.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialog).pop(controller.text), child: const Text(Strings.save)),
        ],
      ),
    );
    controller.dispose();
    if (name != null) await ref.read(placeRepositoryProvider).rename(place.id, name);
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(childrenProvider).value ?? const <Child>[];
    final child = ref.watch(currentChildProvider).value;
    final places = child == null ? const <Place>[] : ref.watch(placesProvider(child.id)).value ?? const [];
    final minutes = _minutes;

    Widget card(String title, List<Widget> body) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [BoxShadow(color: Color(0xFFECE7DD), offset: Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, color: KidColors.inkSoft)),
            const SizedBox(height: 6),
            ...body,
          ]),
        );

    Widget row(Widget leading, String text, {VoidCallback? onTap, Color color = KidColors.ink, Widget? trailing}) => InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 54,
            child: Row(children: [
              leading,
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: TextStyle(fontSize: 17, color: color))),
              trailing ?? (onTap == null ? const SizedBox.shrink() : const KidIcon('chevron', size: 20, color: Color(0xFFB9B2A4))),
            ]),
          ),
        );

    return Scaffold(
      backgroundColor: KidColors.parentBg,
      appBar: AppBar(
        backgroundColor: KidColors.parentBg,
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          ArtSvg(Art.logo, size: 30),
          SizedBox(width: 8),
          Text(Strings.parentMode, style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
            card(Strings.children, [
              for (final c in children)
                row(
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFFFF1DA), shape: BoxShape.circle),
                    child: AnimalArt(c.avatar, size: 40),
                  ),
                  animalNames[c.avatar] ?? c.avatar,
                ),
              if (children.length < animals.length)
                row(const KidIcon('plus', size: 22, color: KidColors.skyDark), Strings.addChild,
                    color: KidColors.skyDark, onTap: () => _addChild([for (final c in children) c.avatar]), trailing: const SizedBox.shrink()),
            ]),
            card(Strings.dailyLimit, [
              if (minutes != null)
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [for (final m in [15, 30, 45, 60]) ButtonSegment(value: m, label: Text(Strings.minutes(m)))],
                  selected: {minutes},
                  onSelectionChanged: (s) {
                    setState(() => _minutes = s.first);
                    ref.read(settingsRepositoryProvider).setDailyMinutes(s.first);
                  },
                ),
              const SizedBox(height: 6),
            ]),
            card(Strings.ourPlaces, [
              const Text(Strings.ourPlacesHint, style: TextStyle(fontSize: 14, color: KidColors.inkSoft)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in places)
                  ActionChip(
                    avatar: ArtSvg(Art.place(PlaceKind.byName(p.kind)), size: 26),
                    label: Text(p.label ?? PlaceKind.byName(p.kind).label),
                    backgroundColor: const Color(0xFFF6F2EA),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    onPressed: () => _rename(p),
                  ),
              ]),
              const SizedBox(height: 6),
            ]),
            card(Strings.voices, [
              // Its own Material: the card's white background would hide the tile's ink.
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(Strings.creatureVoices, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  subtitle: const Text(Strings.creatureVoicesHint, style: TextStyle(fontSize: 14, color: KidColors.inkSoft)),
                  value: ref.watch(voiceOnProvider),
                  onChanged: (on) => ref.read(voiceOnProvider.notifier).set(on),
                ),
              ),
            ]),
            card(Strings.other, [
              row(const KidIcon('shield', size: 22, color: KidColors.grassDark), Strings.privacy, onTap: () => context.push('/parent/privacy')),
              row(const KidIcon('info', size: 22, color: KidColors.inkSoft), Strings.licenses,
                  onTap: () => showLicensePage(context: context, applicationName: Strings.appName, applicationVersion: appVersionLabel)),
              row(const KidIcon('clock', size: 22, color: KidColors.inkSoft), Strings.version(appVersionLabel)),
            ]),
          ]),
        ),
      ),
    );
  }
}
