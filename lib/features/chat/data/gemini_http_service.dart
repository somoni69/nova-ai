import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiHttpService {
  String? _apiKey;

  void init(String apiKey) {
    _apiKey = apiKey;
  }

  Future<String> sendMessage(String text) async {
    if (_apiKey == null) return "Ошибка: Ключ не установлен";

    try {
      // 🔥 ИСПРАВЛЕНИЕ: Используем 'gemini-pro' вместо 'gemini-1.5-flash'
      // Эта ссылка работает стабильно уже год.
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": text}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Если ответ пришел, достаем текст
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
           return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
           return "Google прислал пустой ответ.";
        }
      } else {
        return "Ошибка Google (${response.statusCode}): ${response.body}";
      }
    } catch (e) {
      return "Ошибка сети: $e";
    }
  }
}