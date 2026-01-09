import '../../domain/chat_models.dart'; // Импорт модели

abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatListening extends ChatState {}

class ChatThinking extends ChatState {}

class ChatSuccess extends ChatState {
  final ChatSession currentSession; // Текущий открытый чат
  final List<ChatSession> history; // Список для бокового меню
  final String? attachedImagePath; // 🔥 Для превью картинки
  final bool isGenerating; // 🔥 НОВЫЙ ФЛАГ
  final bool isVoiceMode; // 🔥 Режим разговора
  final String partialText; // 🔥 НОВОЕ ПОЛЕ (Субтитры)

  ChatSuccess({
    required this.currentSession,
    required this.history,
    this.attachedImagePath,
    this.isGenerating = false,
    this.isVoiceMode = false, // 🔥 По умолчанию выключено
    this.partialText = "", // 🔥 По умолчанию пусто
  });
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}
