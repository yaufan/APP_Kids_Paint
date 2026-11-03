import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/town_time.dart';

void main() {
  test('the town is day at noon and night after dinner', () {
    expect(dayPhaseAt(DateTime(2026, 10, 25, 12)), DayPhase.day);
    expect(dayPhaseAt(DateTime(2026, 10, 25, 20)), DayPhase.night);
    expect(dayPhaseAt(DateTime(2026, 10, 25, 3)), DayPhase.night);
  });

  test('dusk follows sunset through the year', () {
    // Late October: the sun sets around 17:20.
    expect(dayPhaseAt(DateTime(2026, 10, 25, 17, 30)), DayPhase.dusk);
    // June: still day at 17:30, dusk at 18:30.
    expect(dayPhaseAt(DateTime(2026, 6, 20, 17, 30)), DayPhase.day);
    expect(dayPhaseAt(DateTime(2026, 6, 20, 18, 30)), DayPhase.dusk);
    // A winter morning before 7 has the dawn colors.
    expect(dayPhaseAt(DateTime(2026, 1, 10, 6, 30)), DayPhase.dusk);
  });

  test('sun times change smoothly across the new year', () {
    final dec = sunTimes(DateTime(2026, 12, 31)), jan = sunTimes(DateTime(2027, 1, 1));
    expect((dec.sunrise - jan.sunrise).abs(), lessThan(3));
    expect((dec.sunset - jan.sunset).abs(), lessThan(3));
  });

  group('a sped-up day (2.2)', () {
    final since = DateTime(2026, 11, 3, 21);

    test('starts with the morning, then dusk, night and dawn, over and over', () {
      DayPhase at(Duration d, [DayCycle cycle = DayCycle.lapse]) => townPhase(since.add(d), cycle, since);
      expect(at(Duration.zero), DayPhase.day, reason: 'even at 9 at night');
      expect(at(const Duration(minutes: 5)), DayPhase.day);
      expect(at(const Duration(minutes: 6)), DayPhase.dusk);
      expect(at(const Duration(minutes: 8)), DayPhase.night);
      expect(at(const Duration(minutes: 9, seconds: 40)), DayPhase.dusk, reason: 'dawn');
      expect(at(const Duration(minutes: 10, seconds: 30)), DayPhase.day, reason: 'a new day');
      expect(at(const Duration(minutes: 2), DayCycle.fast), DayPhase.night);
    });

    test('every phase gets its turn, day the longest', () {
      for (final cycle in [DayCycle.lapse, DayCycle.fast]) {
        final seen = <DayPhase, int>{};
        for (var s = 0; s < cycle.length!.inSeconds; s++) {
          final p = townPhase(since.add(Duration(seconds: s)), cycle, since);
          seen[p] = (seen[p] ?? 0) + 1;
        }
        expect(seen.keys.toSet(), DayPhase.values.toSet());
        expect(seen[DayPhase.day]!, greaterThan(seen[DayPhase.night]!));
      }
    });

    test('by the clock it is the real time of day; sped up is the default', () {
      expect(townPhase(DateTime(2026, 11, 3, 21), DayCycle.real, since), DayPhase.night);
      expect(townPhase(DateTime(2026, 11, 3, 12), DayCycle.real, since), DayPhase.day);
      expect(DayCycle.byName(null), DayCycle.lapse);
      expect(DayCycle.byName('real'), DayCycle.real);
      expect(DayCycle.byName('nonsense'), DayCycle.lapse);
    });
  });
}
