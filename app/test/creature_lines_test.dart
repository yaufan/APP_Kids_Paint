import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/creature_lines.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/festivals.dart';
import 'package:kids_paint/core/weather.dart';

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

  test('the lines follow the moment: a new arrival says hello, taps tickle, festivals and neighbors come up', () {
    final random = math.Random(2);
    final evening = DateTime(2026, 12, 25, 21);
    for (final c in Creature.values) {
      final moment = Moment(time: evening, festival: Festival.christmas, neighbors: [Creature.panda, Creature.milk], taps: 3);
      final lines = linesOf(c, moment);
      for (var i = 0; i < 30; i++) {
        expect(lines, contains(lineFor(c, random, moment)), reason: c.name);
      }
    }
    String often(Creature c, Moment m) {
      final counts = <String, int>{};
      for (var i = 0; i < 400; i++) {
        final line = lineFor(c, random, m);
        counts[line] = (counts[line] ?? 0) + 1;
      }
      return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }

    final lines = [for (var i = 0; i < 200; i++) lineFor(Creature.lion, random, Moment(time: evening, justArrived: true))];
    expect(lines.where((l) => l.contains('搬來')).length, greaterThan(40), reason: 'a new arrival introduces itself');
    expect(['呵呵呵，好癢喔！', '你在跟我玩嗎？', '咻～我跳起來了！', '再一次！再一次！'],
        contains(often(Creature.panda, Moment(time: evening, taps: 4))));
    final christmas = [for (var i = 0; i < 300; i++) lineFor(Creature.bus, random, Moment(time: evening, festival: Festival.christmas))];
    expect(christmas, contains('聖誕節快樂！'));
    final withNeighbor = [for (var i = 0; i < 300; i++) lineFor(Creature.milk, random, Moment(time: evening, neighbors: const [Creature.carrot]))];
    expect(withNeighbor.any((l) => l.contains('胡蘿蔔')), isTrue);
    expect(linesOf(Creature.milk), contains('歡迎光臨！'));
    expect(wantToBuy(Creature.milk, random), contains('牛奶'));
  });

  test('they talk about the weather: rain, sprinkles in the candy house, a rainbow, the wind', () {
    final random = math.Random(3);
    final day = DateTime(2026, 10, 28, 15);
    List<String> heard(Creature c, Weather w) => [for (var i = 0; i < 300; i++) lineFor(c, random, Moment(time: day, weather: w))];
    expect(heard(Creature.lion, Weather.rain).where((l) => l.contains('雨')).length, greaterThan(30));
    expect(heard(Creature.donut, Weather.rain).any((l) => l.contains('糖粒')), isTrue);
    expect(heard(Creature.sunflower, Weather.rain), contains('下雨了！我喝得飽飽的！'));
    expect(heard(Creature.bus, Weather.rainbow).any((l) => l.contains('彩虹')), isTrue);
    expect(heard(Creature.tiger, Weather.windy).any((l) => l.contains('風')), isTrue);
    expect(heard(Creature.lion, Weather.sunny).any((l) => l.contains('下雨')), isFalse);
  });

  test('no line asks a child to stay or makes them feel bad for leaving', () {
    final moment = Moment(time: DateTime(2026, 10, 27, 20), festival: Festival.midAutumn, neighbors: const [], taps: 2);
    final everything = {
      for (final c in Creature.values) ...linesOf(c, moment),
      for (final c in Creature.values) ...linesOf(c, Moment(time: DateTime(2026, 10, 27, 8), justArrived: true, neighbors: Creature.values)),
      for (final c in Creature.values)
        for (final w in Weather.values) ...linesOf(c, Moment(time: DateTime(2026, 10, 27, 14), weather: w)),
    };
    for (final line in everything) {
      expect(line, isNot(matches(RegExp('寂寞|孤單|不要走|別走|難過|哭|不理我|陪我'))), reason: line);
    }
  });
}
