import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/art.dart';
import '../../app/strings.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';

/// A question an adult answers easily but a 2.5–5 year old cannot read:
/// the numbers are written out in Chinese characters.
class ParentGateChallenge {
  ParentGateChallenge(this.a, this.b);

  factory ParentGateChallenge.random([math.Random? random]) {
    final r = random ?? math.Random();
    return ParentGateChallenge(3 + r.nextInt(7), 3 + r.nextInt(7));
  }

  final int a;
  final int b;

  static const _digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

  String get question => Strings.gateQuestion(_digits[a], _digits[b]);

  int get answer => a + b;

  bool check(String answer) => int.tryParse(answer.trim()) == this.answer;
}

/// Shows the parent gate; completes with true only for a correct answer.
Future<bool> showParentGate(BuildContext context) async {
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ParentGatePage()),
  );
  return ok ?? false;
}

/// Full screen, so a child cannot tap past it. The bear asks the child to
/// fetch a grown-up; wrong answers get a new question, and after three in a
/// row the gate waits a minute.
class ParentGatePage extends StatefulWidget {
  const ParentGatePage({super.key});

  static const maxMisses = 3;
  static const lockout = Duration(minutes: 1);

  // Kept for the whole session, so closing and reopening does not reset them.
  static int _misses = 0;
  static DateTime? _lockedUntil;

  @override
  State<ParentGatePage> createState() => _ParentGatePageState();
}

class _ParentGatePageState extends State<ParentGatePage> {
  var _challenge = ParentGateChallenge.random();
  var _typed = '';
  bool _wrong = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_locked && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  bool get _locked {
    final until = ParentGatePage._lockedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _key(String k) {
    if (_locked) return;
    setState(() {
      _wrong = false;
      if (k == '⌫') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
        return;
      }
      if (_typed.length >= 2) return;
      _typed += k;
    });
    final need = '${_challenge.answer}'.length;
    if (_typed.length < need) return;
    if (_challenge.check(_typed)) {
      ParentGatePage._misses = 0;
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _wrong = true;
      _typed = '';
      _challenge = ParentGateChallenge.random();
      if (++ParentGatePage._misses >= ParentGatePage.maxMisses) {
        ParentGatePage._misses = 0;
        ParentGatePage._lockedUntil = DateTime.now().add(ParentGatePage.lockout);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locked = _locked;
    final wait = locked ? ParentGatePage._lockedUntil!.difference(DateTime.now()).inSeconds + 1 : 0;
    final need = '${_challenge.answer}'.length;
    Widget box(int i) => Container(
          width: 64,
          height: 72,
          margin: const EdgeInsets.only(right: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: i < _typed.length ? KidColors.sky : const Color(0xFFD6CFC2), width: 3),
          ),
          child: Text(i < _typed.length ? _typed[i] : '', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
        );
    Widget key(String k) => Semantics(
          key: ValueKey('gate-key-$k'),
          button: true,
          label: k == '⌫' ? Strings.backspace : k,
          excludeSemantics: true,
          child: Pressable(
            onTap: locked ? null : () => _key(k),
            child: Container(
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0xFFE3DCCF), offset: Offset(0, 4))],
              ),
              child: k == '⌫'
                  ? const KidIcon('undo', size: 28, color: KidColors.inkSoft)
                  : Text(k, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: KidColors.parentBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Row(children: [
                const AnimalArt('bear', size: 66),
                const SizedBox(width: 8),
                const Expanded(child: Align(alignment: Alignment.centerLeft, child: VoiceBubble(Strings.callParent))),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: Strings.cancel,
                  excludeSemantics: true,
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(false),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: Color(0xFFEFEAE0), shape: BoxShape.circle),
                      child: const KidIcon('close', size: 22, color: KidColors.inkSoft),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    KidIcon('lock', size: 18, color: KidColors.inkSoft),
                    SizedBox(width: 8),
                    Text(Strings.parentGateTitle, style: TextStyle(fontSize: 15, color: KidColors.inkSoft)),
                  ]),
                  const SizedBox(height: 10),
                  Text(locked ? Strings.gateWait(wait) : _challenge.question, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  if (!locked) Row(children: [for (var i = 0; i < need; i++) box(i)]),
                  const SizedBox(height: 14),
                  Text(_wrong ? Strings.wrongAnswer : Strings.gateRules,
                      style: TextStyle(fontSize: 14, color: _wrong ? const Color(0xFFC2410C) : KidColors.inkSoft)),
                ]),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) key(k),
                  const SizedBox.shrink(),
                  key('0'),
                  key('⌫'),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
