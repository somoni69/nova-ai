import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nova_ai/features/chat/presentation/pages/chat_page.dart';
import 'package:nova_ai/features/auth/auth_page.dart'; // 🔥 Import AuthPage
import 'package:intl/date_symbol_data_local.dart'; // 🔥 ДЛЯ ДАТ
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/data/groq_service.dart'; // 👈 Groq
import 'features/chat/data/speech_service.dart';
import 'features/chat/data/tts_service.dart';
import 'features/settings/settings_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/chat/domain/chat_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🔥 Impost Supabase
import 'api_keys.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerLazySingleton(() => GroqService()); // 👈 Регаем Groq
  getIt.registerLazySingleton(() => SpeechService());
  getIt.registerLazySingleton(() => TtsService());
  getIt.registerLazySingleton(() => SettingsService());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Инит Hive
  await Hive.initFlutter();

  // 2. Регистрируем адаптеры (которые сгенерировал build_runner)
  Hive.registerAdapter(ChatRoleAdapter());
  Hive.registerAdapter(ChatMessageAdapter());
  Hive.registerAdapter(ChatSessionAdapter());

  // 3. Открываем коробку с историей
  await Hive.openBox<ChatSession>('chat_sessions');

  await initializeDateFormatting('ru', null);

  // 🔥 ПОДКЛЮЧАЕМ SUPABASE
  await Supabase.initialize(
    url: ApiKeys.supabaseUrl,
    anonKey: ApiKeys.supabaseKey,
  );

  setupLocator();

  // 🔥 ВАЖНО: Инициализируем настройки до запуска UI
  await getIt<SettingsService>().init();

  // 🔥 ДВА КЛЮЧА
  // Передаем оба в сервис
  getIt<GroqService>().init(
    groqApiKey: ApiKeys.groq,
    googleApiKey: ApiKeys.google,
  );
  await getIt<TtsService>().init();

  runApp(const NovaApp()); // Вынесли в отдельный виджет
}

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = getIt<SettingsService>();

    // Проверяем текущую сессию Supabase
    final session = Supabase.instance.client.auth.currentSession;

    // Слушаем изменения темы
    return BlocProvider(
      create: (context) => ChatBloc(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: settings.themeNotifier,
        builder: (_, mode, __) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Nova AI',
            themeMode: mode, // Текущий режим (Светлый/Темный)
            // ☀️ СВЕТЛАЯ ТЕМА (White & Black)
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: Colors.white, // Белый фон
              primaryColor: Colors.black,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black, // Черный текст и иконки
                elevation: 0,
              ),
              // Цвет пузырей ИИ для светлой темы
              cardColor: Colors.grey[100],
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black),
              ),
            ),

            // 🌑 ТЕМНАЯ ТЕМА (Black & White)
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: Colors.black, // Черный фон
              primaryColor: Colors.white,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              // Цвет пузырей ИИ для темной темы
              cardColor: const Color(0xFF1E1E1E),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
              ),
            ),

            // 🔥 ЕСЛИ ЕСТЬ СЕССИЯ -> ЧАТ, ИНАЧЕ -> ВХОД
            home: session != null ? const ChatPage() : const AuthPage(),
          );
        },
      ),
    );
  }
}
