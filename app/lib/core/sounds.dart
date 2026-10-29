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
  rainbow('rainbow'),
  // The town's toys (0.18).
  quack('quack'),
  honk('honk'),
  toot('toot'),
  firework('firework'),
  drizzle('drizzle'),
  // The residents' calls when tapped, and feeding them (0.19).
  moo('moo'),
  mooLow('moo_low'),
  baa('baa'),
  bleat('bleat'),
  oink('oink'),
  cluck('cluck'),
  peep('peep'),
  woof('woof'),
  yip('yip'),
  goose('goose'),
  meow('meow'),
  eep('eep'),
  roar('roar'),
  bigRoar('big_roar'),
  rawr('rawr'),
  trumpet('trumpet'),
  whinny('whinny'),
  monkey('monkey'),
  grunt('grunt'),
  grumble('grumble'),
  hum('hum'),
  blub('blub'),
  whale('whale'),
  narwhal('narwhal'),
  dolphin('dolphin'),
  click('click'),
  puff('puff'),
  dinoHorn('dino_horn'),
  screech('screech'),
  crack('crack'),
  sirenFire('siren_fire'),
  sirenPolice('siren_police'),
  sirenAmbulance('siren_ambulance'),
  beep('beep'),
  jet('jet'),
  chop('chop'),
  elise('elise'),
  backup('backup'),
  putt('putt'),
  whir('whir'),
  buzz('buzz'),
  slurp('slurp'),
  cicada('cicada'),
  ufo('ufo'),
  alien('alien'),
  squawk('squawk'),
  bark('bark'),
  hoot('hoot'),
  jingle('jingle'),
  serve('serve'),
  munch('munch');

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

/// What a poked toy in the town sounds like ([townToys] kinds).
Sfx toySound(String kind) => switch (kind) {
      'duck' => Sfx.quack,
      'train' => Sfx.toot,
      'tower' => Sfx.firework,
      'cloud' => Sfx.drizzle,
      _ => Sfx.honk,
    };

/// The boing of a creature jumping when tapped: big ones lower.
Sfx boingOf(Creature creature) => creature.size >= 180 ? Sfx.boingLow : (creature.size <= 115 ? Sfx.boingHigh : Sfx.boingMid);

/// What a tapped resident sounds like (0.19): animals call (a cow moos, a
/// bee buzzes, the garbage truck plays Für Elise like in Taiwan), vehicles
/// hoot and wail; plants, sweets and the rest jump with a [boingOf].
Sfx callOf(Creature creature) => switch (creature) {
      Creature.elephant => Sfx.trumpet,
      Creature.giraffe => Sfx.hum,
      Creature.lion || Creature.tiger => Sfx.roar,
      Creature.panda || Creature.seaOtter || Creature.bunny => Sfx.eep,
      Creature.zebra => Sfx.whinny,
      Creature.monkey => Sfx.monkey,
      Creature.hippo || Creature.koala || Creature.walrus => Sfx.grumble,
      Creature.triceratops || Creature.stegosaurus || Creature.ankylosaurus => Sfx.grumble,
      Creature.kangaroo || Creature.blackBear || Creature.polarBear || Creature.reindeer || Creature.pachycephalosaurus => Sfx.grunt,
      Creature.flamingo || Creature.goose => Sfx.goose,
      Creature.clownfish || Creature.octopus || Creature.turtle || Creature.shark || Creature.goldfish => Sfx.blub,
      Creature.whale => Sfx.whale,
      Creature.narwhal => Sfx.narwhal,
      Creature.dolphin || Creature.orca => Sfx.dolphin,
      Creature.jellyfish || Creature.starfish || Creature.butterfly || Creature.firefly => Sfx.sparkle,
      Creature.crab || Creature.seahorse || Creature.mantis || Creature.ant || Creature.spider => Sfx.click,
      Creature.pufferfish => Sfx.puff,
      Creature.trex || Creature.spinosaurus => Sfx.bigRoar,
      Creature.brachiosaurus || Creature.parasaurolophus => Sfx.dinoHorn,
      Creature.pterosaur || Creature.raptor => Sfx.screech,
      Creature.babyDino => Sfx.rawr,
      Creature.dinoEgg => Sfx.crack,
      Creature.fireTruck => Sfx.sirenFire,
      Creature.policeCar => Sfx.sirenPolice,
      Creature.ambulance => Sfx.sirenAmbulance,
      Creature.bus || Creature.taxi => Sfx.honk,
      Creature.scooter => Sfx.beep,
      Creature.train || Creature.mrt => Sfx.toot,
      Creature.airplane => Sfx.jet,
      Creature.helicopter => Sfx.chop,
      Creature.garbageTruck => Sfx.elise,
      Creature.excavator => Sfx.backup,
      Creature.tractor => Sfx.putt,
      Creature.ladybug || Creature.dragonfly => Sfx.whir,
      Creature.bee || Creature.beetle => Sfx.buzz,
      Creature.snail => Sfx.slurp,
      Creature.caterpillar => Sfx.munch,
      Creature.cicada => Sfx.cicada,
      Creature.ufo => Sfx.ufo,
      Creature.alien => Sfx.alien,
      Creature.spaceCat => Sfx.meow,
      Creature.penguin => Sfx.squawk,
      Creature.seal => Sfx.bark,
      Creature.arcticFox => Sfx.yip,
      Creature.snowyOwl => Sfx.hoot,
      Creature.sled => Sfx.jingle,
      Creature.cow => Sfx.moo,
      Creature.waterBuffalo => Sfx.mooLow,
      Creature.pig => Sfx.oink,
      Creature.hen => Sfx.cluck,
      Creature.chick => Sfx.peep,
      Creature.sheep => Sfx.baa,
      Creature.goat => Sfx.bleat,
      Creature.duck => Sfx.quack,
      Creature.puppy => Sfx.woof,
      _ => boingOf(creature),
    };

/// Whether [sfx] is a call of its own rather than a boing.
bool isCall(Sfx sfx) => sfx != Sfx.boingLow && sfx != Sfx.boingMid && sfx != Sfx.boingHigh;
