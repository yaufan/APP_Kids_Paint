import 'package:flutter_tts/flutter_tts.dart';

/// Reads out what the creatures say, for children who cannot read yet.
///
/// It uses the phone's own text-to-speech in Taiwanese Mandarin; parents can
/// turn it off in parent mode. Recorded voices can replace it later.
abstract interface class Voice {
  Future<void> say(String text);
  Future<void> stop();
}

class SystemVoice implements Voice {
  FlutterTts? _tts;

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = _tts = FlutterTts();
    await tts.setLanguage('zh-TW');
    await tts.setSpeechRate(0.45);
    await tts.setPitch(1.25);
    return tts;
  }

  @override
  Future<void> say(String text) async {
    try {
      final tts = await _engine();
      await tts.stop();
      await tts.speak(text);
    } catch (_) {
      // No speech engine (tests, or a phone without one): the bubble is enough.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {}
  }
}

/// Says nothing (voice turned off).
class SilentVoice implements Voice {
  const SilentVoice();

  @override
  Future<void> say(String text) async {}

  @override
  Future<void> stop() async {}
}
