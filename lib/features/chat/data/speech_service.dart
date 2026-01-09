import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isEnabled = false;

  Future<bool> init() async {
    _isEnabled = await _speech.initialize(
      onError: (e) => print('🔴 STT Error: $e'),
      onStatus: (s) => print('🟡 STT Status: $s'),
    );
    return _isEnabled;
  }

  // Обновили сигнатуру: теперь передаем (Текст, ЭтоКонец?)
  void startListening({required Function(String, bool) onResult}) {
    if (_isEnabled) {
      _speech.listen(
        onResult: (result) {
          // Передаем не только текст, но и флаг "finalResult"
          // finalResult = true означает, что человек замолчал и фраза готова
          onResult(result.recognizedWords, result.finalResult);
        },
        // ⚠️ УБРАЛИ localeId - пусть берет системный
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2), // Ждем 2 сек тишины
        partialResults: true, // Включаем частичные результаты
        cancelOnError: true,
      );
    }
  }

  void stop() async {
    await _speech.stop();
  }
}