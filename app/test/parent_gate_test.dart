import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/features/parent/parent_gate.dart';

void main() {
  test('the question spells the numbers out in Chinese characters', () {
    final gate = ParentGateChallenge(7, 8);
    expect(gate.question, '「七」加「八」等於多少？');
    expect(gate.question, isNot(contains(RegExp(r'[0-9]'))));
  });

  test('only the right sum opens the gate', () {
    final gate = ParentGateChallenge(7, 8);
    expect(gate.check('15'), isTrue);
    expect(gate.check(' 15 '), isTrue);
    expect(gate.check('14'), isFalse);
    expect(gate.check(''), isFalse);
    expect(gate.check('abc'), isFalse);
  });

  test('random questions use single digits from 3 to 9', () {
    final random = Random(1);
    for (var i = 0; i < 100; i++) {
      final gate = ParentGateChallenge.random(random);
      expect(gate.a, inInclusiveRange(3, 9));
      expect(gate.b, inInclusiveRange(3, 9));
    }
  });
}
