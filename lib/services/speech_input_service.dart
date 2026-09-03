import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef SpeechResultCallback = void Function(String transcript, bool isFinal);
typedef SpeechStateCallback = void Function(bool isListening);
typedef SpeechErrorCallback = void Function(String message);

abstract interface class SpeechInputService {
  Future<bool> initialize({
    required SpeechStateCallback onListeningChanged,
    required SpeechErrorCallback onError,
  });

  Future<void> start({required SpeechResultCallback onResult});

  Future<void> stop();

  Future<void> cancel();
}

class DeviceSpeechInputService implements SpeechInputService {
  DeviceSpeechInputService({stt.SpeechToText? speechToText})
    : _speechToText = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speechToText;
  SpeechStateCallback? _onListeningChanged;
  SpeechErrorCallback? _onError;
  bool _initialized = false;
  bool _available = false;

  @override
  Future<bool> initialize({
    required SpeechStateCallback onListeningChanged,
    required SpeechErrorCallback onError,
  }) async {
    _onListeningChanged = onListeningChanged;
    _onError = onError;

    if (_initialized) return _available;

    _available = await _speechToText.initialize(
      onStatus: (status) {
        _onListeningChanged?.call(status == stt.SpeechToText.listeningStatus);
      },
      onError: (error) {
        _onListeningChanged?.call(false);
        _onError?.call(_friendlyError(error.errorMsg));
      },
    );
    _initialized = true;
    return _available;
  }

  @override
  Future<void> start({required SpeechResultCallback onResult}) async {
    if (!_available) {
      throw StateError('Speech recognition has not been initialized.');
    }

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        autoPunctuation: true,
        pauseFor: const Duration(seconds: 4),
        listenFor: const Duration(minutes: 1),
      ),
    );
    _onListeningChanged?.call(_speechToText.isListening);
  }

  @override
  Future<void> stop() => _speechToText.stop();

  @override
  Future<void> cancel() => _speechToText.cancel();

  String _friendlyError(String error) {
    if (error.contains('permission')) {
      return 'Microphone access is off. Enable it in system settings or type your response.';
    }
    if (error.contains('no_match') || error.contains('speech_timeout')) {
      return 'I didn’t catch that. Tap the microphone and try again.';
    }
    if (error.contains('network')) {
      return 'Speech recognition needs a connection right now. You can still type your response.';
    }
    return 'Speech input stopped unexpectedly. You can try again or keep typing.';
  }
}
