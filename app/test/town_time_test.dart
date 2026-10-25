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
}
