import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/festivals.dart';

void main() {
  Festival? on(int y, int m, int d) => festivalOn(DateTime(y, m, d, 10))?.festival;

  test('lunar festivals follow the lunar calendar', () {
    expect(on(2027, 2, 5), Festival.lunarNewYear); // New Year's Eve
    expect(on(2027, 2, 10), Festival.lunarNewYear); // the fifth day
    expect(on(2027, 2, 11), isNull);
    expect(on(2027, 2, 20), Festival.lantern);
    expect(on(2026, 6, 19), Festival.dragonBoat);
    expect(on(2026, 9, 25), Festival.midAutumn);
    expect(on(2026, 9, 26), isNull);
  });

  test('fixed-date festivals, including New Year across two years', () {
    expect(on(2026, 4, 4), Festival.childrensDay);
    expect(on(2026, 12, 24), Festival.christmas);
    expect(on(2026, 12, 31), Festival.newYearsEve);
    final newYear = festivalOn(DateTime(2027, 1, 1))!;
    expect((newYear.festival, newYear.first), (Festival.newYearsEve, DateTime(2026, 12, 31)));
    expect(on(2026, 10, 25), isNull);
  });

  test('every year in the table lists its festivals in order, without overlaps', () {
    for (var year = 2026; year < 2038; year++) {
      final days = festivalsIn(year);
      expect(days, hasLength(Festival.values.length), reason: '$year');
      for (var i = 1; i < days.length; i++) {
        expect(days[i].first.isAfter(days[i - 1].last), isTrue, reason: '$year ${days[i].festival}');
      }
    }
  });
}
