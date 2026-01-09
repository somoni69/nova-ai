import '../../domain/chat_models.dart';

abstract class ChatEvent {}

class StartListening extends ChatEvent {}

class LoadFromCloud extends ChatEvent {} // ☁️ Load history from cloud

// 🔥 НОВОЕ СОБЫТИЕ
class ProcessText extends ChatEvent {
  final String text;
  ProcessText(this.text);
}

class LoadSessions extends ChatEvent {} // Загрузить боковую панель

class DeleteCurrentChat extends ChatEvent {}

class AttachImage extends ChatEvent {} // 🔥 НОВОЕ СОБЫТИЕ

class RemoveImage extends ChatEvent {}

class StopGeneration extends ChatEvent {} // 🛑 НОВОЕ СОБЫТИЕ

class ToggleVoiceMode extends ChatEvent {} // 🔥 Вкл/Выкл режим разговора

class SelectSession extends ChatEvent {
  // Нажали на чат в истории
  final ChatSession session;
  SelectSession(this.session);
}

class CreateNewSession extends ChatEvent {} // Кнопка "Новый чат"
