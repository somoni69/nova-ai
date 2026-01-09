// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 1;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      text: fields[0] as String,
      role: fields[1] as ChatRole,
      timestamp: fields[2] as DateTime,
      imagePath: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.role)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.imagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatSessionAdapter extends TypeAdapter<ChatSession> {
  @override
  final int typeId = 2;

  @override
  ChatSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSession(
      id: fields[0] as String,
      title: fields[1] as String,
      messages: (fields[2] as List).cast<ChatMessage>(),
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChatSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.messages)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatRoleAdapter extends TypeAdapter<ChatRole> {
  @override
  final int typeId = 0;

  @override
  ChatRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChatRole.user;
      case 1:
        return ChatRole.ai;
      default:
        return ChatRole.user;
    }
  }

  @override
  void write(BinaryWriter writer, ChatRole obj) {
    switch (obj) {
      case ChatRole.user:
        writer.writeByte(0);
        break;
      case ChatRole.ai:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
