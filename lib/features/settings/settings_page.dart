import 'package:flutter/material.dart';
import '../../../../main.dart';
import 'settings_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final settings = getIt<SettingsService>();
  String _currentPersona = "Ассистент 🤖";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final persona = await settings.getPersonaName();
    setState(() => _currentPersona = persona);
  }

  @override
  Widget build(BuildContext context) {
    // Получаем текущую тему
    final isDark = settings.themeNotifier.value == ThemeMode.dark;

    // БЕРЕМ ТЕМУ ИЗ КОНТЕКСТА (Цвета определены в main.dart)
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Настройки")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔥 ПЕРЕКЛЮЧАТЕЛЬ ТЕМЫ
          SwitchListTile(
            title: const Text("Темная тема"),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            value: isDark,
            onChanged: (val) {
              settings.toggleTheme(val);
              setState(() {}); // Обновляем свитч чтобы перерисовался
            },
          ),
          const Divider(),
          const SizedBox(height: 10),
          const Text("Личность ИИ:", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 10),

          ...SettingsService.personas.keys.map((name) {
            final isSelected = name == _currentPersona;
            return Card(
              // Для карточки используем цвет из темы или подсвечиваем если выбрано
              color: isSelected
                  ? theme.primaryColor.withOpacity(0.1)
                  : theme.cardColor,
              child: ListTile(
                title: Text(name),
                trailing: isSelected
                    ? Icon(Icons.check, color: theme.primaryColor)
                    : null,
                onTap: () async {
                  // Сохраняем и Имя и Промпт (чтобы синхронизировалось)
                  final prompt = SettingsService.personas[name] ?? "";
                  await settings.savePersona(name, prompt);
                  setState(() => _currentPersona = name);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
