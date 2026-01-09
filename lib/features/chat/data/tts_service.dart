import 'package:flutter_tts/flutter_tts.dart';
import 'dart:ui';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> init() async {
    await _flutterTts.setLanguage('ru-RU');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  // Добавляем параметр onDone
  Future<void> speak(String text, {VoidCallback? onDone}) async {
    await _flutterTts.stop();
    if (text.isNotEmpty) {
      // Настраиваем колбек ПЕРЕД началом речи
      if (onDone != null) {
        _flutterTts.setCompletionHandler(() {
          onDone(); // Вызываем функцию, когда речь закончилась
          _flutterTts.setCompletionHandler(
            () {},
          ); // Сбрасываем, чтобы не сработало лишний раз
        });
      }
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
