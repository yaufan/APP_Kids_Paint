/// Festivals the town celebrates: decorations on the map and, for most, a
/// coloring page Gugu brings (docs/feature-ideas.md, idea C).
enum Festival {
  lunarNewYear('過年'),
  lantern('元宵節'),
  childrensDay('兒童節'),
  dragonBoat('端午節'),
  midAutumn('中秋節'),
  christmas('聖誕節'),
  newYearsEve('跨年');

  const Festival(this.label);

  final String label;

  /// New Year's Eve only has fireworks over 101.
  bool get hasPage => this != newYearsEve;

  static Festival? byName(String? name) => values.where((f) => f.name == name).firstOrNull;
}

/// One year's dates of a festival, first and last day included.
typedef FestivalDays = ({Festival festival, DateTime first, DateTime last});

/// Lunar New Year, the Lantern Festival, Dragon Boat and Mid-Autumn as
/// month * 100 + day, from the lunar calendar. The town has no network, so
/// the table is built in; add years before 2038.
const _lunarDates = <int, List<int>>{
  2026: [217, 303, 619, 925],
  2027: [206, 220, 609, 915],
  2028: [126, 209, 528, 1003],
  2029: [213, 227, 616, 922],
  2030: [203, 217, 605, 912],
  2031: [123, 206, 624, 1001],
  2032: [211, 225, 612, 919],
  2033: [131, 214, 601, 908],
  2034: [219, 305, 620, 927],
  2035: [208, 222, 610, 916],
  2036: [128, 211, 530, 1004],
  2037: [215, 301, 618, 924],
};

/// Every festival in [year], in date order.
List<FestivalDays> festivalsIn(int year) {
  DateTime day(int mmdd) => DateTime(year, mmdd ~/ 100, mmdd % 100);
  FestivalDays span(Festival f, DateTime d, int before, [int after = 0]) =>
      (festival: f, first: DateTime(d.year, d.month, d.day - before), last: DateTime(d.year, d.month, d.day + after));
  final lunar = _lunarDates[year];
  return [
    if (lunar != null) ...[
      span(Festival.lunarNewYear, day(lunar[0]), 1, 4), // New Year's Eve to the fifth day
      span(Festival.lantern, day(lunar[1]), 2),
    ],
    span(Festival.childrensDay, DateTime(year, 4, 4), 3, 1),
    if (lunar != null) ...[
      span(Festival.dragonBoat, day(lunar[2]), 3),
      span(Festival.midAutumn, day(lunar[3]), 3),
    ],
    span(Festival.christmas, DateTime(year, 12, 25), 5),
    span(Festival.newYearsEve, DateTime(year, 12, 31), 0, 1),
  ];
}

/// The festival being celebrated on [when]'s date, if any.
FestivalDays? festivalOn(DateTime when) {
  final date = DateTime(when.year, when.month, when.day);
  for (final year in [when.year - 1, when.year]) {
    for (final f in festivalsIn(year)) {
      if (!date.isBefore(f.first) && !date.isAfter(f.last)) return f;
    }
  }
  return null;
}
