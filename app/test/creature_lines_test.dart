import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/creature_lines.dart';
import 'package:kids_paint/core/creatures.dart';

void main() {
  test('every creature has its own things to say, and only says known lines', () {
    final random = math.Random(1);
    for (final c in Creature.values) {
      final lines = linesOf(c);
      expect(lines.length, greaterThan(10), reason: c.name);
      for (var i = 0; i < 20; i++) {
        expect(lines, contains(lineFor(c, random)));
      }
    }
  });
}
