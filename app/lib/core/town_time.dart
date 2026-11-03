/// How the town looks at a time of day. Dawn uses the dusk colors.
enum DayPhase { day, dusk, night }

/// Sunrise and sunset in Taipei on the 15th of each month, in minutes after
/// midnight. The app never asks where the phone is; Taiwan is small enough
/// that Taipei's times are close everywhere.
const _sunrise = [400, 389, 364, 332, 309, 303, 313, 328, 339, 351, 371, 391];
const _sunset = [1045, 1067, 1083, 1096, 1110, 1124, 1126, 1109, 1079, 1047, 1027, 1027];

/// Sunrise and sunset on [date], between the mid-month values.
({int sunrise, int sunset}) sunTimes(DateTime date) {
  // Position in the year counted in months from the 15th of January.
  final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
  final t = (date.month - 1) + (date.day - 15) / daysInMonth;
  final a = t.floor() % 12, b = (t.floor() + 1) % 12;
  final f = t - t.floor();
  int lerp(List<int> v) => (v[a] + (v[b] - v[a]) * f).round();
  return (sunrise: lerp(_sunrise), sunset: lerp(_sunset));
}

/// How the town's day goes by (2.2): with the clock, or sped up so a child
/// sees the sun go down and come up again while playing ([length]: one
/// whole day and night). Sped up is the default.
enum DayCycle {
  real(null),
  lapse(Duration(minutes: 10)),
  fast(Duration(minutes: 3));

  const DayCycle(this.length);

  final Duration? length;

  static DayCycle byName(String? name) => values.where((c) => c.name == name).firstOrNull ?? DayCycle.lapse;
}

/// How the town looks [now]: by the clock ([DayCycle.real]), or in a
/// sped-up day that began with the morning at [since]. A sped-up day is
/// a little more than half day, then dusk, night and dawn.
DayPhase townPhase(DateTime now, DayCycle cycle, DateTime since) {
  final length = cycle.length;
  if (length == null) return dayPhaseAt(now);
  final f = (now.difference(since).inMilliseconds / length.inMilliseconds) % 1;
  if (f < 0.55) return DayPhase.day;
  if (f < 0.65) return DayPhase.dusk;
  if (f < 0.92) return DayPhase.night;
  return DayPhase.dusk;
}

/// Day from half an hour after sunrise, dusk from 40 minutes before sunset
/// to 25 minutes after it (and around sunrise), night in between.
DayPhase dayPhaseAt(DateTime time) {
  final sun = sunTimes(time);
  final m = time.hour * 60 + time.minute;
  if (m >= sun.sunrise + 30 && m < sun.sunset - 40) return DayPhase.day;
  if ((m >= sun.sunset - 40 && m < sun.sunset + 25) || (m >= sun.sunrise - 30 && m < sun.sunrise + 30)) {
    return DayPhase.dusk;
  }
  return DayPhase.night;
}
