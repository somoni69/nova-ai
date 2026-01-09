import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для копирования текста
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../main.dart';
import '../../data/tts_service.dart';
import '../../domain/chat_models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    final ttsService = getIt<TtsService>();
    final theme = Theme.of(context); // 🔥 Берем тему
    final isDark = theme.brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // 1. САМ ТЕКСТ (ПУЗЫРЬ)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // 🔥 ДИНАМИЧЕСКИЕ ЦВЕТА
                // Юзер: Синий (всегда)
                // ИИ: Берем cardColor из темы (Светло-серый или Темно-серый)
                color: isUser ? Colors.blueAccent : theme.cardColor,

                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(18),
                ),
                // Добавим легкую рамку для светлой темы, чтобы пузырь не сливался с белым фоном
                border: !isUser && !isDark
                    ? Border.all(color: Colors.grey.shade300)
                    : null,
              ),
              child: MarkdownBody(
                data: message.text,
                selectable: true, // Можно выделять текст пальцем
                styleSheet: MarkdownStyleSheet(
                  // 🔥 Текст адаптируется (Черный или Белый)
                  p: TextStyle(
                    color: isUser
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  strong: TextStyle(
                    color: isUser
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                  ),
                  // Код всегда на темном фоне для контраста
                  code: const TextStyle(
                    backgroundColor: Color(0xFF2d2d2d),
                    color: Colors.greenAccent,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFF1e1e1e),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // 2. ПАНЕЛЬ УПРАВЛЕНИЯ (ТОЛЬКО ДЛЯ ИИ)
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔊 Кнопка озвучки
                    _IconBtn(
                      icon: Icons.volume_up_rounded,
                      onTap: () {
                        ttsService.speak(message.text);
                      },
                    ),
                    const SizedBox(width: 8),
                    // 📋 Кнопка копирования
                    _IconBtn(
                      icon: Icons.copy_rounded,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Скопировано!"),
                            duration: Duration(milliseconds: 500),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    // 🔄 Кнопка "Стоп" (если вдруг говорит слишком долго)
                    _IconBtn(
                      icon: Icons.stop_circle_outlined,
                      onTap: () {
                        ttsService.stop();
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Маленькая вспомогательная кнопка
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Иконки должны быть видны на любом фоне
    final color = Theme.of(context).iconTheme.color?.withOpacity(0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
