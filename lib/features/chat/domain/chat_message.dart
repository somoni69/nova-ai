enum ChatRole { user, ai }

class ChatMessage {
  final String text;
  final ChatRole role;

  ChatMessage({required this.text, required this.role});

  // Превращаем в Map (для сохранения)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'role': role == ChatRole.user ? 'user' : 'ai',
    };
  }

  // Создаем из Map (для загрузки)
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      text: map['text'],
      role: map['role'] == 'user' ? ChatRole.user : ChatRole.ai,
    );
  }
}