import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'repositories.dart';

/// How long a child has played today, against the daily limit parents set
/// in parent mode.
///
/// The app never stops a child in the middle of a picture: a little before
/// the end the pigeon says time is nearly up, and once it is up the rest
/// screen waits until the picture is finished (`RestCurtain`).
class PlayTime {
  const PlayTime({required this.played, required this.allowed});

  final Duration played;

  /// Null when there is no limit.
  final Duration? allowed;

  /// The pigeon's "nearly time to rest" comes this long before the end.
  static const warnBefore = Duration(minutes: 3);

  /// Past the limit by this much, the rest screen comes even in the middle
  /// of a picture (which waits underneath it).
  static const grace = Duration(minutes: 10);

  Duration? get left => allowed == null ? null : allowed! - played;

  bool get almostOver {
    final l = left;
    return l != null && l > Duration.zero && l <= warnBefore;
  }

  bool get over {
    final l = left;
    return l != null && l <= Duration.zero;
  }

  bool get wayOver {
    final l = left;
    return l != null && -l >= grace;
  }
}

/// `2026-10-27`: the key for a day's play.
String dayOf(DateTime t) => '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// Today's play; null while it loads.
final playTimeProvider = NotifierProvider<PlayClock, PlayTime?>(PlayClock.new);

/// Counts the time the app is open on screen, every [tick], and keeps it
/// in the settings so closing the app does not reset it. A new day starts
/// from nothing.
class PlayClock extends Notifier<PlayTime?> {
  static const tick = Duration(seconds: 15);

  String? _day;
  var _seconds = 0, _extra = 0, _limit = SettingsRepository.defaultDailyMinutes;
  var _onScreen = true;

  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  @override
  PlayTime? build() {
    final timer = Timer.periodic(tick, (_) {
      if (_onScreen) add(tick);
    });
    final lifecycle = AppLifecycleListener(onStateChange: (s) {
      _onScreen = s == AppLifecycleState.resumed;
      if (_onScreen) add(Duration.zero); // back the next morning: a new day
    });
    ref.onDispose(() {
      timer.cancel();
      lifecycle.dispose();
    });
    _load();
    return null;
  }

  Future<void> _load() async {
    final day = dayOf(ref.read(clockProvider)());
    final limit = await _settings.dailyMinutes();
    final play = await _settings.playOn(day);
    if (!ref.mounted) return;
    _day = day;
    _limit = limit;
    _seconds = play.seconds;
    _extra = play.extraMinutes;
    _publish();
  }

  void _publish() => state = PlayTime(
        played: Duration(seconds: _seconds),
        allowed: _limit == SettingsRepository.noLimit ? null : Duration(minutes: _limit + _extra),
      );

  /// [played] more on screen.
  Future<void> add(Duration played) async {
    final day = _day;
    if (day == null) return; // still loading
    final today = dayOf(ref.read(clockProvider)());
    if (today != day) {
      _day = today;
      _seconds = 0;
      _extra = 0;
    }
    _seconds += played.inSeconds;
    _publish();
    await _settings.setPlayOn(_day!, seconds: _seconds, extraMinutes: _extra);
  }

  /// A parent gives [minutes] more today.
  Future<void> extend(int minutes) async {
    _extra += minutes;
    _publish();
    if (_day != null) await _settings.setPlayOn(_day!, seconds: _seconds, extraMinutes: _extra);
  }

  /// After a parent changes the daily limit.
  Future<void> reload() => _load();
}
