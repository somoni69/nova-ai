import 'dart:io';
import 'dart:ui'; // 🔥 Для размытия (BackdropFilter)
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import '../../domain/chat_models.dart';
import 'package:intl/intl.dart';
import '../../../settings/settings_page.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Авто-скролл вниз при новом сообщении
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // При старте грузим историю
    context.read<ChatBloc>().add(LoadSessions());

    // 🔥 ДОБАВЛЯЕМ ЭТО:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<ChatBloc>();
      // Если это первый запуск и истории нет - пробуем скачать из облака
      if (bloc.history.isEmpty) {
        bloc.add(LoadFromCloud());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 БОКОВАЯ ПАНЕЛЬ
      drawer: Drawer(
        // backgroundColor: const Color(0xFF16213E), //  <-- Убрали
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Кнопка "Новый чат"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  context.read<ChatBloc>().add(CreateNewSession());
                  Navigator.pop(context); // Закрыть меню
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Новый чат",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Список чатов
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatSuccess) {
                    return ListView.builder(
                      itemCount: state.history.length,
                      itemBuilder: (context, index) {
                        final session = state.history[index];
                        final isSelected = session == state.currentSession;

                        return ListTile(
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.color,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'dd MMM, HH:mm',
                            ).format(session.createdAt),
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                          onTap: () {
                            context.read<ChatBloc>().add(
                              SelectSession(session),
                            );
                            Navigator.pop(context);
                          },
                          // Кнопка удаления чата
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.white24,
                            ),
                            onPressed: () {
                              session.delete(); // Удаляем из Hive
                              context.read<ChatBloc>().add(
                                LoadSessions(),
                              ); // Обновляем список
                            },
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: BlocBuilder<ChatBloc, ChatState>(
          builder: (context, state) {
            if (state is ChatSuccess) {
              return Text(state.currentSession.title);
            }
            return const Text("Nova AI 🤖");
          },
        ),
        // backgroundColor: const Color(0xFF16213E), // <-- Убрали
        actions: [
          // Кнопка настройки (у тебя уже есть)
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),

          // 🔥 Кнопка Voice Mode
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final isVoice = (state is ChatSuccess) && state.isVoiceMode;

              return IconButton(
                // Меняем иконку и цвет:
                // 🎧 Серый = выкл
                // 🗣️ Зеленый/Синий = вкл
                icon: Icon(
                  isVoice
                      ? Icons.record_voice_over
                      : Icons.headset_mic_outlined,
                  color: isVoice ? Colors.greenAccent : null,
                ),
                onPressed: () {
                  context.read<ChatBloc>().add(ToggleVoiceMode());
                },
              );
            },
          ),

          // 🔥 РАБОЧАЯ КНОПКА УДАЛЕНИЯ
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // Показываем диалог подтверждения
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).cardColor, // Под цвет темы
                  title: Text(
                    "Удалить чат?",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  content: Text(
                    "Переписка будет удалена безвозвратно.",
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Отмена"),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    TextButton(
                      child: const Text(
                        "Удалить",
                        style: TextStyle(color: Colors.redAccent),
                      ),
                      onPressed: () {
                        // 1. Отправляем команду в Блок
                        context.read<ChatBloc>().add(DeleteCurrentChat());
                        // 2. Закрываем диалог
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          // 1. ОСНОВНОЙ ЧАТ
          Column(
            children: [
              // 1. СПИСОК СООБЩЕНИЙ
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    // Скроллим вниз только если пришло сообщение или текст изменился
                    if (state is ChatSuccess) {
                      Future.delayed(
                        const Duration(milliseconds: 50),
                        _scrollToBottom,
                      );
                    }
                  },
                  builder: (context, state) {
                    List<ChatMessage> messages = [];
                    if (state is ChatSuccess) {
                      messages = state.currentSession.messages;
                    }

                    if (messages.isEmpty && state is! ChatSuccess) {
                      return const Center(
                        child: Text(
                          "Начни общение...",
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          messages.length + (state is ChatThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Nova печатает...",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return MessageBubble(message: messages[index]);
                      },
                    );
                  },
                ),
              ),

              // 2. ПАНЕЛЬ ВВОДА (Input Bar)
              // Скрываем панель ввода, если включен Voice Mode (Overlay перекроет всё, но лучше скрыть, чтобы не мешала)
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  // Если режим разговора активен, мы НЕ показываем обычную панель (она будет в оверлее или скрыта)
                  // Но в ТЗ сказано "Вместо того чтобы заменять клавиатуру на черный квадрат, мы накроем весь экран"
                  // Значит основной чат остается под низом.
                  // А панель ввода? Она нам не нужна в режиме разговора.
                  if (state is ChatSuccess && state.isVoiceMode) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      // ПРЕВЬЮ КАРТИНКИ
                      if (state is ChatSuccess &&
                          state.attachedImagePath != null)
                        _buildImagePreview(
                          context,
                          state.attachedImagePath!,
                          Theme.of(context).brightness == Brightness.dark,
                        ),

                      _buildInputPanel(context, state),
                    ],
                  );
                },
              ),
            ],
          ),

          // 2. 🔥 ГОЛОСОВОЙ ОВЕРЛЕЙ (Поверх всего)
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state is ChatSuccess && state.isVoiceMode) {
                return Positioned.fill(
                  child: _buildVoiceOverlay(context, state),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // Вынес в отдельные методы для чистоты
  Widget _buildImagePreview(BuildContext context, String path, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF16213E) : Colors.white,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "Изображение прикреплено",
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => context.read<ChatBloc>().add(RemoveImage()),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context, ChatState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isListening = state is ChatListening;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
            onPressed: () {
              context.read<ChatBloc>().add(AttachImage());
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                hintText: isListening ? "Слушаю..." : "Введите сообщение...",
                hintStyle: TextStyle(color: theme.hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF2E2E3E) : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (text) => _sendMessage(context, text),
            ),
          ),
          const SizedBox(width: 8),
          if (state is ChatSuccess && state.isGenerating)
            CircleAvatar(
              backgroundColor: Colors.grey[700],
              radius: 24,
              child: IconButton(
                icon: const Icon(Icons.stop, color: Colors.white),
                onPressed: () => context.read<ChatBloc>().add(StopGeneration()),
              ),
            )
          else
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, child) {
                final hasText = value.text.isNotEmpty;
                return hasText
                    ? CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        radius: 24,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () =>
                              _sendMessage(context, _textController.text),
                        ),
                      )
                    : AvatarGlow(
                        animate: isListening,
                        glowColor: Colors.blueAccent,
                        duration: const Duration(milliseconds: 2000),
                        repeat: true,
                        child: CircleAvatar(
                          backgroundColor: isListening
                              ? Colors.redAccent
                              : Colors.blueAccent,
                          radius: 24,
                          child: IconButton(
                            icon: Icon(
                              isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              if (!isListening) {
                                context.read<ChatBloc>().add(StartListening());
                              }
                            },
                          ),
                        ),
                      );
              },
            ),
        ],
      ),
    );
  }

  // 🔥 НОВЫЙ МЕТОД: Оверлей для голосового режима
  Widget _buildVoiceOverlay(BuildContext context, ChatSuccess state) {
    // Определяем статус
    String statusText = "Ожидание...";
    Color glowColor = Colors.grey;
    bool isAnimating = false;

    if (state.isGenerating) {
      statusText = "Nova думает...";
      glowColor = Colors.blueAccent;
      isAnimating = true; // Быстро крутится
    } else if (state.partialText.isNotEmpty) {
      statusText = state.partialText; // 🔥 Показываем то, что слышим!
      glowColor = Colors.greenAccent;
      isAnimating = true; // Пульсирует
    } else {
      statusText = "Слушаю...";
      glowColor = Colors.green;
      isAnimating = false; // Просто горит
    }

    return Container(
      color: Colors.black.withOpacity(0.85), // Темная вуаль
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Размытие фона
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // 🧠 ПУЛЬСИРУЮЩИЙ МОЗГ
            AvatarGlow(
              animate: isAnimating,
              glowColor: glowColor,
              duration: const Duration(milliseconds: 2000),
              repeat: true,
              // radius: 100.0, // УДАЛЕНО, ТАК КАК В НОВОЙ ВЕРСИИ НЕТ
              child: CircleAvatar(
                backgroundColor: Colors.black, // Или transparent
                radius: 60,
                child: Icon(
                  state.isGenerating
                      ? Icons.psychology
                      : Icons.mic, // Меняем иконку
                  size: 50,
                  color: glowColor,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 📝 СУБТИТРЫ (ЖИВОЙ ТЕКСТ)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),

            const Spacer(),

            // ❌ КНОПКА ВЫХОДА
            SafeArea(
              child: TextButton.icon(
                icon: const Icon(Icons.close, color: Colors.white54),
                label: const Text(
                  "Выйти из режима",
                  style: TextStyle(color: Colors.white54),
                ),
                onPressed: () {
                  context.read<ChatBloc>().add(ToggleVoiceMode());
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    context.read<ChatBloc>().add(ProcessText(text));
    _textController.clear();
  }
}
