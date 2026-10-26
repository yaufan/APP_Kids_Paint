import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/features/lineart/teed.dart';

double _tanh(double z) => (math.exp(2 * z) - 1) / (math.exp(2 * z) + 1);

void main() {
  test('the Dart port gives the same edges as the NumPy reference', () {
    final teed = Teed.decode(File('assets/models/teed.bin').readAsBytesSync());
    final ref = readTensors(File('test/fixtures/teed_reference.bin').readAsBytesSync());
    final input = ref['input']!; // (3, h, w), channels first
    final h = input.shape[1], w = input.shape[2];
    final bgr = Float32List(h * w * 3);
    for (var c = 0; c < 3; c++) {
      for (var i = 0; i < h * w; i++) {
        bgr[i * 3 + c] = input.data[c * h * w + i];
      }
    }
    final outs = teed.run(bgr, w, h);
    for (var k = 0; k < 4; k++) {
      final expected = ref['out$k']!.data;
      expect(outs[k].length, expected.length);
      var worst = 0.0;
      for (var i = 0; i < expected.length; i++) {
        worst = math.max(worst, (outs[k][i] - expected[i]).abs());
      }
      expect(worst, lessThan(1e-3), reason: 'output $k');
    }
  });

  test('smish matches its definition', () {
    for (final x in [-6.0, -1.0, 0.0, 0.5, 3.0]) {
      final s = 1 / (1 + math.exp(-x));
      expect(smish(x), closeTo(x * _tanh(math.log(1 + s)), 1e-9));
    }
  });
}
