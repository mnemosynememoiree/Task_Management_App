import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService {
  SpeechService._();
  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required void Function(SpeechRecognitionResult result) onResult,
    void Function(String status)? onStatus,
  }) async {
    if (!_isInitialized) {
      final available = await initialize();
      if (!available) return;
    }
    await _speech.listen(
      onResult: onResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }
}
