// lib/widgets/chat/chat_input_bar.dart
// Bottom message-composer bar — multiline text field + send button.
// Enter sends the message; Shift+Enter inserts a newline (desktop/web).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';

class ChatInputBar extends StatefulWidget {
  final bool isSending;
  final ValueChanged<String> onSend;

  const ChatInputBar({super.key, required this.isSending, required this.onSend});

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (widget.isSending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.numpadEnter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) {
      return KeyEventResult.ignored; // Shift+Enter = newline
    }
    _handleSend();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(top: BorderSide(color: Color(0xFF1F1F1F), width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Focus(
                  onKeyEvent: _handleKey,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.5,
                      fontFamily: 'Poppins',
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    decoration: const InputDecoration(
                      hintText: 'Ask Astra anything… (Enter to send)',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _handleSend,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (_hasText && !widget.isSending)
                      ? const LinearGradient(colors: AppColors.primaryGradient)
                      : null,
                  color: (_hasText && !widget.isSending) ? null : AppColors.surfaceVariant,
                ),
                child: widget.isSending
                    ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
                )
                    : Icon(Icons.arrow_upward_rounded,
                    color: _hasText ? Colors.white : AppColors.textMuted, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}