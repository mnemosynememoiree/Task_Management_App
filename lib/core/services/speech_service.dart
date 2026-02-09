import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Singleton wrapper around the [SpeechToText] plugin.
///
/// Provides a simplified API for initializing, starting, stopping,
/// and cancelling speech recognition.
class SpeechService {
  SpeechService._();

  /// The shared singleton instance.
  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  bool get isListening => _speech.isListening;
  bool get isAvailable => _isInitialized;

  /// Initializes speech recognition; returns `true` if available.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    _isInitialized = await _speech.initialize(
      onError: (error) {},
      onStatus: (status) {},
    );
    return _isInitialized;
  }

  /// Starts listening for speech with the given [onResult] callback.
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

  /// Stops listening and finalizes the recognition result.
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Cancels the current listening session and discards partial results.
  Future<void> cancelListening() async {
    await _speech.cancel();
  }
}
