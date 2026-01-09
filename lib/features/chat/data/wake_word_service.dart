import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine.dart';

class WakeWordService {
  PorcupineManager? _porcupineManager;
  final String _accessKey; // Твой ключ от Picovoice

  // Колбек, который мы дернем, когда услышим слово
  final Function() onWakeWordDetected;

  WakeWordService(this._accessKey, {required this.onWakeWordDetected});

  Future<void> init() async {
    try {
      // Инициализируем Porcupine на слово "Jarvis"
      _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
        _accessKey,
        [
          BuiltInKeyword.JARVIS,
        ], // Можно выбрать PICOVOICE, PORCUPINE, BUMBLEBEE и т.д.
        _wakeWordCallback,
        errorCallback: _errorCallback,
      );
      print("🦜 Wake Word Service готов (Жду 'Jarvis')");
    } on PorcupineException catch (e) {
      print("🔴 Ошибка Porcupine: $e");
    }
  }

  Future<void> startListening() async {
    try {
      await _porcupineManager?.start();
      print("👂 Слушаю эфир...");
    } on PorcupineException catch (e) {
      print("🔴 Не могу начать слушать: $e");
    }
  }

  Future<void> stopListening() async {
    await _porcupineManager?.stop();
    print("zzz Перестал слушать эфир");
  }

  void _wakeWordCallback(int keywordIndex) {
    if (keywordIndex == 0) {
      print("🚀 УСЛЫШАЛ JARVIS!");
      onWakeWordDetected(); // Дергаем внешний метод
    }
  }

  void _errorCallback(PorcupineException error) {
    print("🔴 Ошибка внутри Porcupine: $error");
  }

  // Обязательно освобождаем ресурсы
  Future<void> dispose() async {
    await _porcupineManager?.delete();
  }
}
