import 'package:hive/hive.dart';

part 'chat_models.g.dart';

@HiveType(typeId: 0)
enum ChatRole {
  @HiveField(0)
  user,
  @HiveField(1)
  ai,
}

@HiveType(typeId: 1)
class ChatMessage {
  @HiveField(0)
  final String text;
  @HiveField(1)
  final ChatRole role;
  @HiveField(2)
  final DateTime timestamp;

  // 🔥 НОВОЕ ПОЛЕ (Индекс 3, так как 0,1,2 заняты)
  @HiveField(3)
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.role,
    required this.timestamp,
    this.imagePath, // Необязательное
  });

  // 🔥 ДОБАВЬ ЭТОТ МЕТОД
  ChatMessage copyWith({String? text, String? imagePath}) {
    return ChatMessage(
      text: text ?? this.text,
      role: role,
      timestamp: timestamp,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

@HiveType(typeId: 2)
class ChatSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  List<ChatMessage> messages;

  @HiveField(3)
  DateTime createdAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
  });
}
