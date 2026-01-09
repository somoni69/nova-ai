import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../main.dart';
import '../../data/groq_service.dart';
import '../../data/speech_service.dart';
import '../../data/tts_service.dart';
import '../../domain/chat_models.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import '../../../settings/settings_service.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Не забудь импорт

import 'dart:async'; // 👈
import '../../data/wake_word_service.dart'; // Не забудь
import '../../data/tools_service.dart'; // 🔥 Импорт сервиса инструментов
import 'package:nova_ai/api_keys.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final speechService = getIt<SpeechService>();
  final groqService = getIt<GroqService>();
  final ttsService = getIt<TtsService>();
  final settingsService = getIt<SettingsService>();
  final _supabase = Supabase.instance.client; // 🔥 КЛИЕНТ БАЗЫ
  final ToolsService _toolsService = ToolsService(); // 🔥 Сервис инструментов

  WakeWordService? _wakeWordService;
  final String _picoKey = ApiKeys.picovoice;

  StreamSubscription? _generationSubscription; // 👈 ХРАНИМ ПОДПИСКУ

  // Коробка Hive
  final Box<ChatSession> _sessionsBox = Hive.box<ChatSession>('chat_sessions');

  ChatSession? _currentSession;
  String? _pendingImagePath; // 🔥 Временный путь к картинке
  bool _isVoiceMode = false; // 🔥 Храним состояние режима здесь

  ChatBloc() : super(ChatInitial()) {
    _initWakeWord();

    // 🔥 ОБРАБОТКА ПЕРЕКЛЮЧЕНИЯ РЕЖИМА
    on<ToggleVoiceMode>((event, emit) {
      _isVoiceMode = !_isVoiceMode; // Переключаем

      if (_isVoiceMode) {
        // Если включили — сразу начинаем слушать (чтобы не ждать "Jarvis")
        add(StartListening());
      } else {
        // Если выключили — останавливаем всё лишнее
        speechService.stop();
        ttsService.stop();
      }

      _emitSuccess(emit);
    });

    on<LoadFromCloud>((event, emit) async {
      // 1. Проверяем, залогинен ли юзер
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      emit(ChatThinking()); // Показываем крутилку

      try {
        // 2. Качаем сообщения из Supabase (сортируем по времени)
        final List<dynamic> data = await _supabase
            .from('messages')
            .select()
            .order('created_at', ascending: true); // От старых к новым

        if (data.isEmpty) {
          _emitSuccess(emit);
          return;
        }

        // 3. Создаем новую сессию для восстановленных (или берем текущую)
        if (_currentSession == null) {
          _createNewSessionInternal();
          _currentSession!.title = "Восстановленный чат";
        }

        // 4. Конвертируем JSON из базы в наши объекты
        for (var row in data) {
          final text = row['text'] as String;
          final isUser = row['is_user'] as bool;
          final timeStr = row['created_at'] as String;

          _currentSession!.messages.add(
            ChatMessage(
              text: text,
              role: isUser ? ChatRole.user : ChatRole.ai,
              timestamp: DateTime.parse(timeStr),
            ),
          );
        }

        // 5. Сохраняем в Hive и обновляем экран
        _currentSession!.save();
        _emitSuccess(emit);
      } catch (e) {
        emit(ChatError("Ошибка восстановления: $e"));
      }
    });

    // 1. Загрузка истории при старте
    // Обработка удаления текущего чата
    on<DeleteCurrentChat>((event, emit) {
      if (_currentSession != null) {
        _currentSession!.delete(); // Удаляем из Hive навсегда
        _currentSession = null; // Забываем текущую сессию
      }

      // 🔥 Удаляем из Supabase
      _deleteFromCloud();

      // Перезагружаем список (там логика сама выберет следующий чат или создаст новый)
      add(LoadSessions());
    });

    on<LoadSessions>((event, emit) {
      final sessions = _sessionsBox.values.toList();
      // Сортируем: новые сверху
      sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Если есть сессии, открываем последнюю, иначе создаем новую
      if (sessions.isNotEmpty && _currentSession == null) {
        _currentSession = sessions.first;
      } else if (_currentSession == null) {
        _createNewSessionInternal();
      }

      _emitSuccess(emit);
    });

    // 2. Создание нового чата
    on<CreateNewSession>((event, emit) {
      _createNewSessionInternal();
      _emitSuccess(emit);
    });

    // 3. Выбор чата из истории
    on<SelectSession>((event, emit) {
      _currentSession = event.session;
      _emitSuccess(emit);
    });

    // 🔥 3.1 Прикрепление картинки
    on<AttachImage>((event, emit) async {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        _pendingImagePath = image.path;
        _emitSuccess(emit); // Обновляем UI, чтобы показать превью
      }
    });

    // 🔥 3.2 Очистка картинки
    on<RemoveImage>((event, emit) {
      _pendingImagePath = null;
      _emitSuccess(emit);
    });

    // 0. Слушаем микрофон (Оставляем как было)
    on<StartListening>((event, emit) async {
      await _wakeWordService?.stopListening(); // 🛑 Выключаем "уши" Jarvis

      // Сразу показываем, что начали слушать (можно добавить звук "дзынь")
      _emitSuccess(emit, partialText: "Слушаю...");

      try {
        final available = await speechService.init();
        if (!available) {
          emit(ChatError("Нет микрофона"));
          return;
        }

        // emit(ChatListening()); // <-- УБИРАЕМ, чтобы не сбрасывать UI
        // Вместо этого используем _emitSuccess, чтобы оставаться в ChatSuccess с isVoiceMode

        speechService.startListening(
          onResult: (text, isFinal) {
            if (isFinal) {
              // Финал - отправляем в обработку
              if (text.isNotEmpty) {
                speechService.stop();
                add(ProcessText(text));
              } else {
                // Если тишина - перезапускаем слушалку (если режим включен)
                if (_isVoiceMode) add(StartListening());
              }
            } else {
              // 🔥 ПРОМЕЖУТОЧНЫЙ РЕЗУЛЬТАТ - обновляем экран!
              // Чтобы юзер видел: "При...", "Привет...", "Привет как..."
              _emitSuccess(emit, partialText: text);
            }
          },
        );
      } catch (e) {
        emit(ChatError("Ошибка: $e"));
      }
    });

    // 🛑 СОБЫТИЕ ОСТАНОВКИ
    on<StopGeneration>((event, emit) async {
      await _generationSubscription?.cancel(); // Отменяем поток
      _generationSubscription = null;

      // Если была загрузка - переводим в успех (оставляем то, что успело написаться)
      if (state is ChatSuccess && (state as ChatSuccess).isGenerating) {
        _emitSuccess(emit);
      }
      _wakeWordService?.startListening(); // 👂 Снова ждем "Джарвис"
    });

    // 4. Обработка сообщения (ГЛАВНАЯ ЛОГИКА)
    on<ProcessText>((event, emit) async {
      if (_currentSession == null) _createNewSessionInternal();
      final session = _currentSession!;

      // 1. Добавляем сообщение Юзера
      final userMsg = ChatMessage(
        text: event.text,
        role: ChatRole.user,
        timestamp: DateTime.now(),
        imagePath: _pendingImagePath, // 🔥 Прикрепляем картинку (если есть)
      );
      session.messages.add(userMsg);

      _syncToCloud(event.text, true); // 🔥 ОТПРАВЛЯЕМ В ОБЛАКО (ЮЗЕР)

      // Запоминаем путь, чтобы передать в API, т.к. _pendingImagePath скоро очистим
      final imagePathToSend = _pendingImagePath;
      _pendingImagePath = null; // 🧹 Очищаем "скрепку"

      // 🔥 ЛОГИКА УМНОГО ЗАГОЛОВКА
      if (session.messages.length <= 2) {
        // Запускаем генерацию в фоне
        groqService.generateChatTitle(event.text).then((newTitle) {
          session.title = newTitle;
          session.save();
        });
      } else {
        session.save();
      }

      // Показываем сообщение юзера и говорим, что начали думать
      _emitSuccess(emit, isGenerating: true);

      try {
        // 2. Создаем ПУСТОЕ сообщение от ИИ (заготовку)
        final aiMsgPlaceholder = ChatMessage(
          text: "", // Пока пусто
          role: ChatRole.ai,
          timestamp: DateTime.now(),
        );
        session.messages.add(aiMsgPlaceholder);
        _emitSuccess(
          emit,
          isGenerating: true,
        ); // На экране появится пустой пузырь

        // 3. Готовим историю и запускаем поток
        final apiHistory = await _buildHistoryForApi(session);

        // 🔥 ВМЕСТО await for МЫ ДЕЛАЕМ listen И СОХРАНЯЕМ ПОДПИСКУ
        final stream = groqService.streamMessage(
          apiHistory,
          imagePath: imagePathToSend,
        );

        // Создаем Completer, чтобы BLoC ждал завершения стрима (иначе функция завершится сразу)
        final completer = Completer<void>();

        String accumulatedText = "";

        _generationSubscription = stream.listen(
          (chunk) {
            accumulatedText += chunk;
            // Пришел кусочек текста
            final lastMsg = session.messages.last;
            final updatedMsg = lastMsg.copyWith(text: lastMsg.text + chunk);
            session.messages.removeLast();
            session.messages.add(updatedMsg);

            // Эмитим обновление (без сохранения в Hive каждый раз для скорости)
            _emitSuccess(emit, isGenerating: true);
          },
          onDone: () async {
            String finalText = accumulatedText;

            // 🔦 1. ПРОВЕРКА ФОНАРИКА
            if (finalText.contains('[[FLASH_ON]]')) {
              await _toolsService.toggleFlashlight(true);
              finalText = finalText.replaceAll('[[FLASH_ON]]', '').trim();
            }
            if (finalText.contains('[[FLASH_OFF]]')) {
              await _toolsService.toggleFlashlight(false);
              finalText = finalText.replaceAll('[[FLASH_OFF]]', '').trim();
            }

            // 🌐 2. ПРОВЕРКА БРАУЗЕРА
            // Ищем паттерн [[OPEN:url]]
            final urlRegex = RegExp(r'\[\[OPEN:(.*?)\]\]');
            final match = urlRegex.firstMatch(finalText);
            if (match != null) {
              final url = match.group(1);
              if (url != null) {
                await _toolsService.openUrl(url);
                finalText = finalText.replaceAll(match.group(0)!, '').trim();
              }
            }

            // Сохраняем ЧИСТЫЙ текст в базу и историю
            session.messages.removeLast(); // Удаляем сообщение с тегами
            session.messages.add(
              ChatMessage(
                // Добавляем чистое
                text: finalText,
                role: ChatRole.ai,
                timestamp: DateTime.now(),
              ),
            );

            session.save(); // Сохраняем в конце

            // 2. КОГДА ИИ ЗАКОНЧИЛ ПИСАТЬ - сохраняем чистый текст!
            _syncToCloud(finalText, false); // 🔥 ОТПРАВЛЯЕМ В ОБЛАКО (ИИ)

            completer.complete();

            // 🔥 АВТО-ОЗВУЧКА И ЗАЦИКЛИВАНИЕ
            // Если включен Voice Mode или просто авто-озвучка
            if (_isVoiceMode) {
              await ttsService.speak(
                finalText, // 🔥 Озвучиваем чистый текст
                onDone: () {
                  // ♻️ ИИ замолчал -> Включаем микрофон снова!
                  // Важно: проверяем, не выключил ли юзер режим, пока ИИ болтал
                  if (_isVoiceMode) {
                    add(StartListening());
                  }
                },
              );
            }
          },
          onError: (e) {
            emit(ChatError("Ошибка потока: $e"));
            completer.complete();
          },
        );

        // Ждем, пока поток не закончится или его не отменят
        await completer.future;
        _generationSubscription = null;

        // Обновляем UI, что закончили
        _emitSuccess(emit, isGenerating: false);
      } catch (e) {
        // Если ошибка - удаляем пустой пузырь ИИ, чтобы не висел
        if (session.messages.isNotEmpty &&
            session.messages.last.role == ChatRole.ai &&
            session.messages.last.text.isEmpty) {
          session.messages.removeLast();
        }
        emit(ChatError("Ошибка: $e"));
      } finally {
        // ✅ Когда ИИ закончил говорить — снова ждем "Джарвис"
        await _wakeWordService?.startListening();
      }
    });
  }

  void _createNewSessionInternal() {
    final newSession = ChatSession(
      id: DateTime.now().toString(),
      title: "Новый чат",
      messages: [],
      createdAt: DateTime.now(),
    );
    // Добавляем в базу
    _sessionsBox.add(newSession);
    _currentSession = newSession;
  }

  void _emitSuccess(
    Emitter<ChatState> emit, {
    bool isGenerating = false,
    String partialText = "", // 🔥 Добавили аргумент
  }) {
    final history = _sessionsBox.values.toList();
    history.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    emit(
      ChatSuccess(
        currentSession: _currentSession!,
        history: history,
        attachedImagePath: _pendingImagePath, // 🔥 Передаем в UI
        isGenerating: isGenerating, // 🔥 Передаем флаг
        isVoiceMode: _isVoiceMode, // 🔥 Передаем текущий режим
        partialText: partialText, // 🔥 Передаем в стейт
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _buildHistoryForApi(
    ChatSession session,
  ) async {
    // 1. Узнаем, кто мы сегодня (Йода, Программист и т.д.)
    // 🔥 Теперь берем актуальный промпт (кастомный или дефолтный)
    final baseSystemPrompt = await settingsService.getSystemPrompt();

    final now = DateTime.now();
    // Формат: "четверг, 26 декабря 2024, 14:35"
    final formattedDate = DateFormat(
      'EEEE, d MMMM yyyy, HH:mm',
      'ru',
    ).format(now);

    // 🔥 2. ДОБАВЛЯЕМ ЕГО В ИНСТРУКЦИЮ
    final systemInstruction =
        """
$baseSystemPrompt

Текущая дата и время: $formattedDate.
Ты всегда точно знаешь, какой сегодня день и час.

У тебя есть доступ к функциям телефона. Используй специальные теги В КОНЦЕ ответа, если нужно выполнить действие:
- Если просят включить фонарик/свет -> добавь [[FLASH_ON]]
- Если просят выключить фонарик -> добавь [[FLASH_OFF]]
- Если просят открыть сайт (например Google, YouTube) -> добавь [[OPEN:ссылка]], например [[OPEN:https://youtube.com]]

Отвечай кратко и по делу. Теги пиши только если это уместно.""";

    // 2. Вставляем это в System Message
    final List<Map<String, dynamic>> apiMessages = [
      {
        "role": "system",
        "content": systemInstruction, // 🔥 ТЕПЕРЬ ОНО ДИНАМИЧЕСКОЕ
      },
    ];

    // 🔥 СКОЛЬЗЯЩЕЕ ОКНО (CONTEXT WINDOW)
    const int contextLimit = 20; // 20 сообщений (примерно 10 пар вопрос-ответ)
    List<ChatMessage> messagesToSend = session.messages;

    if (session.messages.length > contextLimit) {
      messagesToSend = session.messages.sublist(
        session.messages.length - contextLimit,
      );
    }

    for (var msg in messagesToSend) {
      apiMessages.add({
        "role": msg.role == ChatRole.user ? "user" : "assistant",
        "content": msg.text,
      });
    }

    return apiMessages;
  }

  Future<void> _initWakeWord() async {
    _wakeWordService = WakeWordService(
      _picoKey,
      onWakeWordDetected: () {
        // 🔥 ЭТО МАГИЯ: Когда слышим "Jarvis", вызываем событие микрофона
        add(StartListening());
      },
    );
    await _wakeWordService?.init();
    await _wakeWordService?.startListening(); // Сразу начинаем слушать
  }

  @override
  Future<void> close() {
    _wakeWordService?.dispose();
    return super.close();
  }

  // 🗑️ УДАЛЕНИЕ ИЗ ОБЛАКА
  Future<void> _deleteFromCloud() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Удаляем ВСЕ сообщения этого юзера
      await _supabase.from('messages').delete().eq('user_id', user.id);
      print("☁️ Облако очищено");
    } catch (e) {
      print("☁️ Ошибка удаления из облака: $e");
    }
  }

  // ☁️ ФУНКЦИЯ СОХРАНЕНИЯ В ОБЛАКО
  Future<void> _syncToCloud(String text, bool isUser) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return; // Если не залогинен - не сохраняем

    // ... existing implementation
    try {
      await _supabase.from('messages').insert({
        'user_id': user.id,
        'text': text,
        'is_user': isUser, // true - Юзер, false - ИИ
      });
    } catch (e) {
      print("☁️ Ошибка синхронизации: $e");
    }
  }

  // 🔥 GETTER FOR HISTORY
  List<ChatSession> get history => _sessionsBox.values.toList();
}
