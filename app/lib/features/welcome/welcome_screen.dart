import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/places.dart';
import '../../core/providers.dart';

/// The first screen on the first day: name the town (the name in front
/// of 的小鎮; a parent types it) and pick the animal friend who shows the child around.
/// Leaving the name empty keeps the animal's name ("小熊的小鎮").
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _name = TextEditingController();
  String? _buddy;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pick(String animal) {
    setState(() => _buddy = animal);
    ref.read(voiceProvider).say(Strings.buddySays(animalNames[animal] ?? ''));
  }

  Future<void> _go(String buddy) async {
    setState(() => _saving = true);
    try {
      final child = await ref.read(currentChildProvider.future);
      await ref.read(childRepositoryProvider).update(child.id, name: _name.text, avatar: buddy);
      await ref.read(settingsRepositoryProvider).setWelcomed();
      ref.invalidate(welcomedProvider);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buddy = _buddy ?? ref.watch(currentChildProvider).value?.avatar ?? animals.first;
    final buddyName = animalNames[buddy] ?? '';
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const ArtSvg(Art.logo, size: 64),
                  const SizedBox(height: 8),
                  const Text(Strings.welcome, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text(Strings.welcomeHint, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: KidColors.inkSoft)),
                  const SizedBox(height: 18),
                  PopIn(
                    key: ValueKey(buddy),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 112,
                        height: 112,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xFFFFF1DA), shape: BoxShape.circle, boxShadow: KidShadows.soft()),
                        child: AnimalArt(buddy, size: 92),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: VoiceBubble(Strings.buddySays(buddyName), fontSize: 16, maxWidth: 220)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  // The town's name: a parent types, the child watches it appear.
                  Semantics(
                    label: Strings.townName,
                    textField: true,
                    child: Row(children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('town-name'),
                          controller: _name,
                          maxLength: 8,
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                          decoration: InputDecoration(
                            counterText: '',
                            hintText: buddyName,
                            hintStyle: const TextStyle(color: Color(0xFFBDB3A3)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(Strings.townSuffix, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  const Text(Strings.pickBuddy, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: KidColors.inkSoft)),
                  const SizedBox(height: 10),
                  Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
                    for (final a in animals)
                      ChunkyButton(
                        key: ValueKey('buddy-$a'),
                        label: animalNames[a] ?? a,
                        selected: a == buddy,
                        width: 78,
                        height: 78,
                        radius: 26,
                        depth: 6,
                        color: a == buddy ? const Color(0xFFFFE08A) : Colors.white,
                        edge: a == buddy ? KidColors.sunDark : const Color(0xFFE6DCCB),
                        onPressed: () => _pick(a),
                        child: AnimalArt(a, size: 58),
                      ),
                  ]),
                  const SizedBox(height: 26),
                  ChunkyButton(
                    label: Strings.letsGo,
                    width: 240,
                    height: 76,
                    color: KidColors.grass,
                    edge: KidColors.grassDark,
                    onPressed: _saving ? null : () => _go(buddy),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      KidIcon('check', size: 30, color: Colors.white),
                      SizedBox(width: 10),
                      Text(Strings.letsGo, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

