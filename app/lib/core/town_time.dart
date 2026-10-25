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
