import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/speech_service.dart';
import '../core/services/voice_task_parser.dart';

/// Lifecycle states of the speech recognition flow.
enum SpeechStatus { idle, initializing, listening, processing, done, error }

/// Immutable snapshot of the current speech recognition state.
class SpeechState {
  final SpeechStatus status;
  final String recognizedText;
  final String? errorMessage;
  final ParsedVoiceTask? parsedTask;

  const SpeechState({
    this.status = SpeechStatus.idle,
    this.recognizedText = '',
    this.errorMessage,
    this.parsedTask,
  });

  SpeechState copyWith({
    SpeechStatus? status,
    String? recognizedText,
    String? errorMessage,
    ParsedVoiceTask? parsedTask,
  }) {
    return SpeechState(
      status: status ?? this.status,
      recognizedText: recognizedText ?? this.recognizedText,
      errorMessage: errorMessage,
      parsedTask: parsedTask ?? this.parsedTask,
    );
  }
}

/// Manages the speech-to-task lifecycle: initialize, listen, parse, reset.
class SpeechNotifier extends StateNotifier<SpeechState> {
  SpeechNotifier() : super(const SpeechState());

  final SpeechService _service = SpeechService.instance;

  Future<void> initialize() async {
    state = state.copyWith(status: SpeechStatus.initializing);
    final available = await _service.initialize();
    if (available) {
      state = state.copyWith(status: SpeechStatus.idle);
    } else {
      state = SpeechState(
        status: SpeechStatus.error,
        errorMessage: 'Speech recognition is not available on this device.',
      );
    }
  }

  Future<void> startListening() async {
    if (!_service.isInitialized) {
      await initialize();
      if (state.status == SpeechStatus.error) return;
    }

    state = state.copyWith(
      status: SpeechStatus.listening,
      recognizedText: '',
    );

    await _service.startListening(
      onResult: (result) {
        if (!mounted) return;
        state = state.copyWith(recognizedText: result.recognizedWords);
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          // Speech engine stopped on its own (pause/timeout)
        }
      },
    );
  }

  void finishAndParse({List<String> categoryNames = const []}) {
    _service.stopListening();

    final text = state.recognizedText.trim();
    if (text.isEmpty) {
      state = SpeechState(
        status: SpeechStatus.error,
        errorMessage: 'No speech detected. Please try again.',
      );
      return;
    }

    state = state.copyWith(status: SpeechStatus.processing);

    final parsed = VoiceTaskParser.parse(text, categoryNames: categoryNames);
    state = state.copyWith(
      status: SpeechStatus.done,
      parsedTask: parsed,
    );
  }

  void cancel() {
    _service.cancelListening();
    state = const SpeechState();
  }

  void reset() {
    state = const SpeechState();
  }
}

final speechNotifierProvider =
    StateNotifierProvider.autoDispose<SpeechNotifier, SpeechState>((ref) {
  return SpeechNotifier();
});
