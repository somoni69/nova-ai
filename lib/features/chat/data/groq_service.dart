import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class GroqService {
  String? _groqApiKey;
  String? _googleApiKey;

  // 🔥 СПИСОК РАБОЧИХ МОДЕЛЕЙ (Заполнится сам после проверки)
  String _visionModel = "gemini-1.5-flash";

  Future<String> generateChatTitle(String messageText) async {
    if (_groqApiKey == null) return "Новый чат";

    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile", // Используем Llama
          "messages": [
            {
              "role": "system",
              "content":
                  "Ты генератор заголовков. Прочитай сообщение пользователя и придумай короткое название для чата (максимум 4 слова). Не используй кавычки. Только текст названия. Язык: Русский.",
            },
            {"role": "user", "content": messageText},
          ],
          "temperature": 0.5,
          "max_tokens": 20, // Нам нужно всего пару слов
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'].trim();
      }
    } catch (e) {
      print("Ошибка генерации заголовка: $e");
    }
    return "Новый чат"; // Если не вышло
  }

  void init({required String groqApiKey, required String googleApiKey}) {
    _groqApiKey = groqApiKey;
    _googleApiKey = googleApiKey;
    print("🔧 Сервис инициализирован.");

    // 🔥 ЗАПУСКАЕМ ПРОВЕРКУ ПРИ СТАРТЕ
    _checkAvailableModels();
  }

  // 🕵️‍♂️ ДЕТЕКТИВ: Спрашиваем у Google, какие модели есть
  Future<void> _checkAvailableModels() async {
    if (_googleApiKey == null) return;

    print("🕵️‍♂️ Проверяем доступные модели Google...");
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$_googleApiKey',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List models = data['models'] ?? [];

        print("✅ GOOGLE РАЗРЕШИЛ ДОСТУП К МОДЕЛЯМ:");
        bool foundFlash = false;

        for (var m in models) {
          String name = m['name'].toString().replaceFirst('models/', '');
          print("   🔹 $name"); // Выведет в консоль, например: gemini-1.5-flash

          if (name.contains('flash') && !name.contains('8b')) {
            _visionModel = name; // Нашли Flash! Берем его.
            foundFlash = true;
          }
        }

        if (foundFlash) {
          print("🎯 Будем использовать модель: $_visionModel");
        } else {
          print("⚠️ Flash не найден. Будем пробовать: $_visionModel");
        }
      } else {
        print("🔴 ОШИБКА ДОСТУПА К СПИСКУ МОДЕЛЕЙ: ${response.statusCode}");
        print("Тело ответа: ${response.body}");
      }
    } catch (e) {
      print("🔴 Ошибка сети при проверке моделей: $e");
    }
  }

  Stream<String> streamMessage(
    List<Map<String, dynamic>> history, {
    String? imagePath,
  }) async* {
    if (imagePath != null) {
      yield* _streamGeminiVision(history, imagePath);
    } else {
      yield* _streamGroqText(history);
    }
  }

  // --- 👁️ ЛОГИКА GEMINI (VISION) ---
  Stream<String> _streamGeminiVision(
    List<Map<String, dynamic>> history,
    String imagePath,
  ) async* {
    if (_googleApiKey == null) {
      yield "❌ Нет ключа Google API";
      return;
    }

    // 1. Сжимаем
    Uint8List bytes;
    try {
      var compressed = await FlutterImageCompress.compressWithFile(
        imagePath,
        minWidth: 1024,
        minHeight: 1024,
        quality: 70,
      );
      bytes = compressed ?? await File(imagePath).readAsBytes();
    } catch (e) {
      bytes = await File(imagePath).readAsBytes();
    }
    final base64Image = base64Encode(bytes);

    String lastUserText = history.isNotEmpty
        ? history.last['content'] as String
        : "Что на фото?";

    // 🔥 ИСПОЛЬЗУЕМ ТО, ЧТО НАШЕЛ ДЕТЕКТИВ
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_visionModel:generateContent?key=$_googleApiKey',
    );

    print("📡 Запрос к Google ($_visionModel)...");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": lastUserText},
                {
                  "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": base64Image,
                  },
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) yield text;
      } else {
        // Если ошибка - выводим подробности, чтобы понять причину
        yield "Ошибка Google (${response.statusCode}): ${response.body}";
        print("🔴 ERROR BODY: ${response.body}");
      }
    } catch (e) {
      yield "Ошибка сети: $e";
    }
  }

  // --- 📝 ЛОГИКА GROQ (ТОЛЬКО ТЕКСТ) ---
  Stream<String> _streamGroqText(List<Map<String, dynamic>> history) async* {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final request = http.Request('POST', url);
    request.headers.addAll({
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $_groqApiKey',
    });

    request.body = jsonEncode({
      "model": "llama-3.3-70b-versatile",
      "messages": history,
      "temperature": 0.6,
      "max_tokens": 1024,
      "stream": true,
    });

    try {
      final response = await http.Client().send(request);
      if (response.statusCode != 200) {
        throw Exception("Groq Error ${response.statusCode}");
      }
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());
      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            final content = json['choices']?[0]?['delta']?['content'];
            if (content != null) yield content as String;
          } catch (e) {}
        }
      }
    } catch (e) {
      throw Exception("Ошибка Groq: $e");
    }
  }
}
