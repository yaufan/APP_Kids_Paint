import 'dart:math' as math;

import 'creatures.dart';
import 'town_time.dart';

/// The town's weather (0.16). It is made up: the app never goes online or
/// asks where the phone is. Mostly sunny, sometimes cloudy, windy or rainy,
/// and a rainbow after the rain.
enum Weather { sunny, cloudy, rain, rainbow, windy }

/// How long the same weather lasts.
const weatherSpell = Duration(hours: 2);

/// How long the rainbow stays after the rain stops.
const rainbowFor = Duration(minutes: 45);

/// The weather at [time]: the same all through each two-hour spell, and the
/// same on every phone and every time the app opens.
Weather weatherAt(DateTime time) {
  final hours = time.difference(DateTime(2026)).inMinutes / 60;
  final spell = (hours / weatherSpell.inHours).floor();
  final weather = _spell(spell);
  if (weather != Weather.rain && _spell(spell - 1) == Weather.rain) {
    final since = Duration(minutes: ((hours - spell * weatherSpell.inHours) * 60).floor());
    // A rainbow needs the sun: none at night.
    if (since < rainbowFor && dayPhaseAt(time) != DayPhase.night) return Weather.rainbow;
  }
  return weather;
}

Weather _spell(int spell) {
  final r = math.Random(spell * 7919 + 17).nextDouble();
  if (r < 0.55) return Weather.sunny;
  if (r < 0.72) return Weather.cloudy;
  if (r < 0.86) return Weather.rain;
  return Weather.windy;
}

/// Whether [habitat] is out in the weather (null: the town). Under the
/// sea, in the shop and in space it does not reach; the polar sea has its
/// own snow.
bool weatherReaches(Habitat? habitat) => switch (habitat) {
      null || Habitat.zoo || Habitat.dinoPark || Habitat.transport || Habitat.botanical || Habitat.insects => true,
      Habitat.nightMarket || Habitat.candy => true,
      Habitat.aquarium || Habitat.shop || Habitat.space || Habitat.polar => false,
    };
