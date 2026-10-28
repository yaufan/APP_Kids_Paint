import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'creatures.dart';
import 'town_time.dart';
import 'weather.dart';

/// Short sounds: a tap, a pop, a boing (app/assets/sounds/, made in
/// docs/design/sounds/make_sounds.py from sine waves and noise).
enum Sfx {
  tap('tap'),
  pick('pick'),
  fill('fill'),
  swish('swish'),
  stamp('stamp'),
  squeak('squeak'),
  undo('undo'),
  sparkle('sparkle'),
  tada('tada'),
  hooray('hooray'),
  boingLow('boing_low'),
  boingMid('boing_mid'),
  boingHigh('boing_high'),
  send('send'),
  rocket('rocket'),
  ding('ding'),
  coin('coin'),
  chime('chime'),
  lullaby('lullaby'),
  rainbow('rainbow');

  const Sfx(this.file);

  final String file;
}

/// A place's background sound, looping quietly.
enum Ambience {
  birds('amb_birds'),
  rain('amb_rain'),
  wind('amb_wind'),
  bubbles('amb_bubbles'),
  space('amb_space'),
  crickets('amb_crickets'),
  twinkle('amb_twinkle');

  const Ambience(this.file);

  final String file;
}

/// The app's sounds. Screens [hold] the background sound they want while
/// they are open; the one opened last is heard, and when it [release]s, the
/// one under it comes back (the town under a place, a place under the canvas).
abstract interface class Sounds {
  /// Off in parent mode: nothing plays, the background sound stops.
  set enabled(bool on);

  void play(Sfx sfx);

  void hold(Object owner, Ambience? ambience);

  void release(Object owner);
}

/// Who wants which background sound: the one that came last is heard;
/// one already there keeps its place when it changes what it wants.
class AmbienceHolders {
  final _holders = <Object, Ambience?>{};

  void hold(Object owner, Ambience? ambience) => _holders[owner] = ambience;

  void release(Object owner) => _holders.remove(owner);

  Ambience? get current => _holders.isEmpty ? null : _holders.values.last;
}

/// No sounds (tests).
class SilentSounds implements Sounds {
  const SilentSounds();

  @override
  set enabled(bool on) {}

  @override
  void play(Sfx sfx) {}

  @override
  void hold(Object owner, Ambience? ambience) {}

  @override
  void release(Object owner) {}
}

/// Sounds through the `audioplayers` plugin. They mix with the voice and
/// with other apps, and follow the phone's silent switch.
class SystemSounds implements Sounds {
  SystemSounds() {
    _lifecycle = AppLifecycleListener(onHide: () => _setAway(true), onShow: () => _setAway(false));
  }

  static const _sfxVolume = 0.8, _ambienceVolume = 0.35;

  late final AppLifecycleListener _lifecycle;
  final _pools = <Sfx, Future<AudioPool>>{};
  final _holders = AmbienceHolders();
  Future<void>? _setUp;
  AudioPlayer? _loop;
  Ambience? _playing;
  var _enabled = true, _away = false;

  @override
  set enabled(bool on) {
    if (on == _enabled) return;
    _enabled = on;
    _update();
  }

  void _setAway(bool away) {
    _away = away;
    _update();
  }

  Future<void> _ready() => _setUp ??= AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers, respectSilence: true).build(),
      );

  @override
  void play(Sfx sfx) {
    if (!_enabled || _away) return;
    unawaited(_play(sfx));
  }

  Future<void> _play(Sfx sfx) async {
    try {
      await _ready();
      final pool = await (_pools[sfx] ??= AudioPool.createFromAsset(path: 'sounds/${sfx.file}.wav', maxPlayers: 3));
      await pool.start(volume: _sfxVolume);
    } catch (_) {
      // No audio (a phone without it, or it failed once): silence is fine.
      _pools.remove(sfx);
    }
  }

  @override
  void hold(Object owner, Ambience? ambience) {
    _holders.hold(owner, ambience);
    _update();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _update();
  }

  Ambience? get _wanted => !_enabled || _away ? null : _holders.current;

  void _update() {
    final wanted = _wanted;
    if (wanted == _playing) return;
    _playing = wanted;
    unawaited(_switchTo(wanted));
  }

  Future<void> _switchTo(Ambience? ambience) async {
    try {
      await _ready();
      var loop = _loop;
      if (loop == null) {
        loop = _loop = AudioPlayer();
        await loop.setReleaseMode(ReleaseMode.loop);
      }
      await loop.stop();
      if (ambience == null || ambience != _playing) return;
      await loop.setVolume(_ambienceVolume);
      await loop.play(AssetSource('sounds/${ambience.file}.wav'));
    } catch (_) {}
  }

  void dispose() {
    _lifecycle.dispose();
    unawaited(_loop?.dispose());
  }
}

/// What is heard at [habitat] (null: the town) in [weather] at [phase]:
/// the rain or the wind when they reach it, else the place's own sound.
Ambience? ambienceFor(Habitat? habitat, Weather weather, DayPhase phase) {
  if (weatherReaches(habitat) && habitat != Habitat.candy) {
    if (weather == Weather.rain) return Ambience.rain;
    if (weather == Weather.windy) return Ambience.wind;
  }
  return switch (habitat) {
    Habitat.aquarium => Ambience.bubbles,
    Habitat.space => Ambience.space,
    Habitat.polar => Ambience.wind,
    Habitat.nightMarket => Ambience.crickets,
    Habitat.candy => Ambience.twinkle, // even when it rains sprinkles
    Habitat.shop => null,
    _ => phase == DayPhase.night ? Ambience.crickets : Ambience.birds,
  };
}

/// The boing of a creature jumping when tapped: big ones lower.
Sfx boingOf(Creature creature) => creature.size >= 180 ? Sfx.boingLow : (creature.size <= 115 ? Sfx.boingHigh : Sfx.boingMid);
