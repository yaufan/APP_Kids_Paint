import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/strings.dart';

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

  String get question => '請輸入「${_digits[a]}」加「${_digits[b]}」的答案';

  bool check(String answer) => int.tryParse(answer.trim()) == a + b;
}

/// Shows the parent gate; completes with true only for a correct answer.
Future<bool> showParentGate(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _ParentGateDialog(ParentGateChallenge.random()),
  );
  return ok ?? false;
}

class _ParentGateDialog extends StatefulWidget {
  const _ParentGateDialog(this.challenge);

  final ParentGateChallenge challenge;

  @override
  State<_ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<_ParentGateDialog> {
  final _answer = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.challenge.check(_answer.text)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = Strings.wrongAnswer);
      _answer.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(Strings.parentGateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.challenge.question),
          TextField(
            controller: _answer,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(hintText: Strings.parentGateHint, errorText: _error),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text(Strings.cancel)),
        FilledButton(onPressed: _submit, child: const Text(Strings.confirm)),
      ],
    );
  }
}
