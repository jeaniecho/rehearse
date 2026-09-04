import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

typedef SpeakingStateCallback = void Function(bool isSpeaking);

/// Reads the other person's lines aloud so a rehearsal sounds like the
/// conversation you are dreading, not a chat transcript.
abstract interface class SpeechOutputService {
  /// Returns false when the device has no usable voice; the app then stays
  /// silent rather than surfacing an error, since speech is an enhancement.
  Future<bool> initialize({required SpeakingStateCallback onSpeakingChanged});

  Future<void> speak(String text);

  Future<void> stop();
}

class DeviceSpeechOutputService implements SpeechOutputService {
  DeviceSpeechOutputService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  SpeakingStateCallback? _onSpeakingChanged;
  bool _initialized = false;
  bool _available = false;

  @override
  Future<bool> initialize({
    required SpeakingStateCallback onSpeakingChanged,
  }) async {
    _onSpeakingChanged = onSpeakingChanged;
    if (_initialized) return _available;
    _initialized = true;

    try {
      // Share the audio session so speaking does not stop the user's own
      // audio outright, and duck instead of interrupting.
      //
      // defaultToSpeaker is deliberately absent: iOS only accepts it with
      // playAndRecord, and setting it here made the whole setCategory call
      // fail. flutter_tts catches that failure and returns 0 rather than
      // throwing, so the app carried on with no category applied at all —
      // which is the default session, and the default session stops
      // whatever the person was listening to. Playback already routes to
      // the speaker, so nothing is lost by dropping it.
      //
      // mixWithOthers is implied by duckOthers, but stated because the
      // point of this block is that other audio keeps playing.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts
            .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, const [
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              IosTextToSpeechAudioCategoryOptions.duckOthers,
            ]);
      }

      await _tts.setLanguage('en-US');
      await _tts.setPitch(1);
      await _tts.setSpeechRate(await _naturalRate());
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() => _onSpeakingChanged?.call(true));
      _tts.setCompletionHandler(() => _onSpeakingChanged?.call(false));
      _tts.setCancelHandler(() => _onSpeakingChanged?.call(false));
      _tts.setErrorHandler((_) => _onSpeakingChanged?.call(false));

      _available = true;
    } on Object {
      _available = false;
    }
    return _available;
  }

  @override
  Future<void> speak(String text) async {
    if (!_available || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } on Object {
      _onSpeakingChanged?.call(false);
    }
  }

  @override
  Future<void> stop() async {
    if (!_available) return;
    try {
      await _tts.stop();
    } on Object {
      // Nothing was playing, or the engine already tore down.
    }
    _onSpeakingChanged?.call(false);
  }

  /// Conversational speed differs per engine: Android treats 1.0 as normal
  /// while iOS treats 0.5 as normal, so ask the platform rather than guess.
  Future<double> _naturalRate() async {
    try {
      final range = await _tts.getSpeechRateValidRange;
      return range.normal.clamp(range.min, range.max);
    } on Object {
      return defaultTargetPlatform == TargetPlatform.android ? 1.0 : 0.5;
    }
  }
}
