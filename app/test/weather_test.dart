import 'package:flutter_test/flutter_test.dart';
import 'package:kids_paint/core/creatures.dart';
import 'package:kids_paint/core/sounds.dart';
import 'package:kids_paint/core/town_time.dart';
import 'package:kids_paint/core/weather.dart';

void main() {
  final start = DateTime(2026, 1, 1);
  final spells = [for (var i = 0; i < 12 * 365; i++) start.add(weatherSpell * i)];

  test('the weather stays the same through a spell, and is the same every time', () {
    for (final time in spells.take(200)) {
      final noon = time.add(const Duration(hours: 1, minutes: 50));
      final w = weatherAt(noon);
      if (w == Weather.rainbow) continue; // the rainbow fades within the spell
      expect(weatherAt(time.add(const Duration(minutes: 55))), w, reason: '$time');
      expect(weatherAt(noon), w);
    }
  });

  test('mostly sunny; every kind of weather comes', () {
    final counts = {for (final w in Weather.values) w: 0};
    for (final time in spells) {
      counts[weatherAt(time.add(const Duration(minutes: 10)))] = counts[weatherAt(time.add(const Duration(minutes: 10)))]! + 1;
    }
    expect(counts[Weather.sunny]!, greaterThan(spells.length * 0.4));
    for (final w in Weather.values) {
      expect(counts[w], greaterThan(0), reason: '$w');
    }
  });

  test('a rainbow comes only right after rain, and never at night', () {
    var rainbows = 0;
    for (final time in spells) {
      final early = time.add(const Duration(minutes: 10));
      if (weatherAt(early) != Weather.rainbow) continue;
      rainbows++;
      expect(weatherAt(time.subtract(const Duration(minutes: 30))), Weather.rain, reason: '$time');
      expect(dayPhaseAt(early), isNot(DayPhase.night));
      expect(weatherAt(time.add(rainbowFor + const Duration(minutes: 5))), isNot(Weather.rainbow));
    }
    expect(rainbows, greaterThan(10));
  });

  test('outdoors gets the weather; under the sea, the shop and space do not', () {
    expect([null, Habitat.zoo, Habitat.candy, Habitat.nightMarket].every(weatherReaches), isTrue);
    expect([Habitat.aquarium, Habitat.shop, Habitat.space, Habitat.polar].any(weatherReaches), isFalse);
  });

  test('each place has its sound; rain and wind are heard outdoors', () {
    expect(ambienceFor(Habitat.zoo, Weather.sunny, DayPhase.day), Ambience.birds);
    expect(ambienceFor(null, Weather.sunny, DayPhase.night), Ambience.crickets);
    expect(ambienceFor(Habitat.zoo, Weather.rain, DayPhase.day), Ambience.rain);
    expect(ambienceFor(Habitat.botanical, Weather.windy, DayPhase.day), Ambience.wind);
    expect(ambienceFor(Habitat.aquarium, Weather.rain, DayPhase.day), Ambience.bubbles, reason: 'no rain under the sea');
    expect(ambienceFor(Habitat.space, Weather.sunny, DayPhase.day), Ambience.space);
    expect(ambienceFor(Habitat.candy, Weather.rain, DayPhase.day), Ambience.twinkle, reason: 'it rains sprinkles there');
    expect(ambienceFor(Habitat.shop, Weather.sunny, DayPhase.day), isNull);
  });

  test('the place opened last is heard, and the one under it comes back', () {
    final holders = AmbienceHolders();
    final town = Object(), zoo = Object();
    holders.hold(town, Ambience.birds);
    holders.hold(zoo, Ambience.rain);
    expect(holders.current, Ambience.rain);
    holders.hold(town, Ambience.crickets); // night falls in the town under the zoo
    expect(holders.current, Ambience.rain);
    holders.release(zoo);
    expect(holders.current, Ambience.crickets);
    holders.release(town);
    expect(holders.current, isNull);
  });

  test('big creatures boing low, small ones high', () {
    expect(boingOf(Creature.whale), Sfx.boingLow);
    expect(boingOf(Creature.ladybug), Sfx.boingHigh);
    expect(boingOf(Creature.lion), Sfx.boingMid);
  });
}
