// lib/widgets/chat/chat_bubble.dart
// Renders a single chat message — user bubbles on the right (brand gradient),
// assistant bubbles on the left (dark surface + AI avatar), with light
// **bold** / "- bullet" markdown support and no extra package dependency.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/chat_message.dart';
import '../../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;

  const ChatBubble({super.key, required this.message, this.isStreaming = false});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _AiAvatar(isError: message.isError),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser
                        ? null
                        : (message.isError
                            ? AppColors.error.withValues(alpha: 0.12)
                            : AppColors.surfaceVariant),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: !isUser
                        ? Border.all(
                            color: message.isError
                                ? AppColors.error.withValues(alpha: 0.3)
                                : const Color(0xFF2A2A2A),
                          )
                        : null,
                  ),
                  child: _RichTextBody(
                    text: message.content.isEmpty ? '…' : message.content,
                    color: message.isError ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatTime(message.createdAt),
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.08, curve: Curves.easeOut);
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _AiAvatar extends StatelessWidget {
  final bool isError;
  const _AiAvatar({this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isError
            ? null
            : const LinearGradient(
                colors: [Color(0xFF6C35DE), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isError ? AppColors.error.withValues(alpha: 0.2) : null,
      ),
      child: Icon(
        isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
        color: isError ? AppColors.error : Colors.white,
        size: 14,
      ),
    );
  }
}

/// Extremely small markdown-lite renderer — handles **bold** inline and
/// "- " / "* " / "1. " list lines — without pulling in a markdown package.
class _RichTextBody extends StatelessWidget {
  final String text;
  final Color color;
  const _RichTextBody({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: lines.map((line) {
        final isBullet = line.trimLeft().startsWith('- ') || line.trimLeft().startsWith('* ');
        final display = isBullet ? line.trimLeft().substring(2) : line;
        final content = Text.rich(
          _parseBold(display, color),
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14.5, height: 1.45, color: color),
        );
        if (line.trim().isEmpty) return const SizedBox(height: 6);
        if (isBullet) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                ),
                Expanded(child: content),
              ],
            ),
          );
        }
        return Padding(padding: const EdgeInsets.only(bottom: 2), child: content);
      }).toList(),
    );
  }

  TextSpan _parseBold(String line, Color color) {
    final regex = RegExp(r'\*\*(.+?)\*\*');
    final spans = <TextSpan>[];
    int last = 0;
    for (final match in regex.allMatches(line)) {
      if (match.start > last) {
        spans.add(TextSpan(text: line.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      last = match.end;
    }
    if (last < line.length) {
      spans.add(TextSpan(text: line.substring(last)));
    }
    return TextSpan(children: spans);
  }
}
