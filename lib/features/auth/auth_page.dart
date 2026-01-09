import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../main.dart'; // Для getIt
import '../settings/settings_service.dart'; // Для SettingsService
import '../chat/presentation/pages/chat_page.dart'; // Путь к твоему чату

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true; // Переключатель Вход / Регистрация

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        // 🔑 ВХОД
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );

        // 🔥 СКАЧИВАЕМ НАСТРОЙКИ ПОСЛЕ ВХОДА
        await getIt<SettingsService>().loadSettingsFromCloud();
      } else {
        // 📝 РЕГИСТРАЦИЯ
        await supabase.auth.signUp(email: email, password: password);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Регистрация успешна! Входим...")),
          );
        }
      }

      // Если всё ок -> идем в Чат
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const ChatPage()));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ошибка сети"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Логотип
              Icon(Icons.psychology, size: 80, color: theme.primaryColor),
              const SizedBox(height: 20),
              Text(
                "Nova AI",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 40),

              // Поля ввода
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Пароль",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),

              // Кнопка
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: isDark
                        ? Colors.black
                        : Colors.white, // Текст кнопки
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLogin ? "Войти" : "Создать аккаунт"),
                ),
              ),

              const SizedBox(height: 16),
              // Переключатель
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin
                      ? "Нет аккаунта? Зарегистрироваться"
                      : "Уже есть аккаунт? Войти",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
