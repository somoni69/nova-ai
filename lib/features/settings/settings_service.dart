import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsService {
  static const String _keySystemPrompt = 'system_prompt';
  static const String _keyPersonaName = 'persona_name'; // 🔥 Имя персоны
  static const String _keyIsDark = 'is_dark_mode'; // Новая настройка

  final _supabase = Supabase.instance.client;

  // 🔥 СЛУШАТЕЛЬ ИЗМЕНЕНИЙ ТЕМЫ
  final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  static const Map<String, String> personas = {
    "Ассистент 🤖":
        "Ты полезный и вежливый ассистент. Отвечай кратко и по делу.",
    "Программист 💻":
        "Ты Senior Developer. Отвечай кодом, объясняй технические детали, используй Markdown.",
    "Стендапер 🤡":
        "Ты дерзкий комик. Шути в каждом ответе, используй сарказм.",
    "Йода 👽": "Ты мастер Йода. Глаголы в конец ставь ты. Мудрость вещай.",
  };

  // Инициализация при старте приложения
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_keyIsDark);

    if (isDark != null) {
      themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  // Переключение темы
  Future<void> toggleTheme(bool isDark) async {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsDark, isDark);
  }

  // 🔥 ОБНОВЛЕННЫЙ МЕТОД СОХРАНЕНИЯ
  Future<void> savePersona(String name, String prompt) async {
    // 1. Сохраняем локально
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPersonaName, name);
    await prefs.setString(_keySystemPrompt, prompt);

    // 2. Сохраняем в ОБЛАКО
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'ai_name': name,
          'system_prompt': prompt,
          'updated_at': DateTime.now().toIso8601String(),
        });
        print("☁️ Настройки сохранены в облако");
      } catch (e) {
        print("Ошибка сохранения профиля: $e");
      }
    }
  }

  // 🔥 МЕТОД ЗАГРУЗКИ ИЗ ОБЛАКА
  Future<void> loadSettingsFromCloud() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        await savePersona(
          data['ai_name'] ?? 'Ассистент 🤖',
          data['system_prompt'] ?? '',
        );
        print("☁️ Настройки подтянулись из облака!");
      }
    } catch (e) {
      print("Ошибка загрузки профиля: $e");
    }
  }

  // ⚠️ Старый метод для совместимости (вызывает новый с дефолтным промптом)
  Future<void> savePersonaName(String personaName) async {
    final prompt = getPromptText(personaName);
    await savePersona(personaName, prompt);
  }

  Future<String> getPersonaName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPersonaName) ?? "Ассистент 🤖";
  }

  // 🔥 Получить текущий промпт (кастомный или дефолтный)
  Future<String> getSystemPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySystemPrompt) ?? personas.values.first;
  }

  String getPromptText(String name) {
    return personas[name] ?? personas.values.first;
  }
}
