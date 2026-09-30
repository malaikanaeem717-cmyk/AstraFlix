// lib/screens/chat/chat_screen.dart
// Full conversational AI chatbot — the "AI" tab in the bottom nav.
// ChatGPT/Claude-style: left sidebar of past chats, streaming replies,
// and a clean empty state with quick-start prompts.
//
// Shows the user's message immediately (optimistic echo) instead of waiting
// for the Firestore round-trip, so sending never looks like the message
// vanished while a new chat session is being created.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/chat_message.dart';
import '../../providers/app_providers.dart';
import '../../providers/chat_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat/chat_bubble.dart';
import '../../widgets/chat/chat_history_drawer.dart';
import '../../widgets/chat/chat_input_bar.dart';
import '../../widgets/chat/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  // Shown immediately on send, before Firestore confirms the write —
  // cleared once the real message shows up in the live stream.
  ChatMessage? _optimisticUserMessage;
  String? _lastError;

  static const List<String> _quickPrompts = [
    'Recommend me a mind-bending thriller',
    'What should I watch tonight?',
    'Explain the ending of Inception',
    'Best sci-fi movies of the last 5 years',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(String uid, String? chatId, List<ChatMessage> history, String text) {
    setState(() {
      _optimisticUserMessage = ChatMessage(
        id: 'optimistic_${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.user,
        content: text,
        createdAt: DateTime.now(),
      );
      _lastError = null;
    });
    _scrollToBottom();

    ref
        .read(chatControllerProvider)
        .sendMessage(uid: uid, chatId: chatId, text: text, priorHistory: history)
        .whenComplete(() {
      if (!mounted) return;
      setState(() => _optimisticUserMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final activeChatId = ref.watch(activeChatIdProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Please sign in to chat with Astra.',
                style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
              ),
            ),
          );
        }
        return _buildChat(context, user.uid, activeChatId);
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (_, __) => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Something went wrong.',
              style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins')),
        ),
      ),
    );
  }

  Widget _buildChat(BuildContext context, String uid, String? chatId) {
    final messages = chatId == null
        ? const AsyncValue<List<ChatMessage>>.data(<ChatMessage>[])
        : ref.watch(chatMessagesProvider(chatId));
    final isSending = chatId != null ? ref.watch(isSendingProvider(chatId)) : false;
    final streamingText = chatId != null ? ref.watch(streamingTextProvider(chatId)) : '';
    final chatError = chatId != null ? ref.watch(chatErrorProvider(chatId)) : null;

    // Surface a save/send failure once, as a snackbar, instead of it being
    // swallowed silently.
    if (chatError != null && chatError != _lastError) {
      _lastError = chatError;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatError, style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: ChatHistoryDrawer(uid: uid),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFF6C35DE), AppColors.primary]),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
            const Text('Astra AI', style: TextStyle(fontSize: 17)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () {
              setState(() => _optimisticUserMessage = null);
              ref.read(activeChatIdProvider.notifier).state = null;
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.when(
                data: (msgs) {
                  // Drop the optimistic bubble once the real message has
                  // landed anywhere in the Firestore stream — checking only
                  // the last message was a bug: once the AI's reply became
                  // the last message, the check flipped back to "not landed"
                  // and the optimistic bubble reappeared, duplicated, at the
                  // bottom of the list.
                  final optimistic = _optimisticUserMessage;
                  final alreadyLanded = optimistic != null &&
                      msgs.any((m) => m.role == ChatRole.user && m.content == optimistic.content);
                  final showOptimistic = optimistic != null && !alreadyLanded;

                  // Same idea for the assistant's streamed reply: once the
                  // real message has landed in Firestore (msgs.last matches
                  // it), stop showing the local streaming bubble/typing dots
                  // — regardless of exactly when the provider clears its
                  // buffer. This is what was causing a brief flash of empty
                  // "..." dots (or a duplicated answer) right after the
                  // reply finished.
                  final assistantLanded = streamingText.isNotEmpty &&
                      msgs.isNotEmpty &&
                      msgs.last.role == ChatRole.assistant &&
                      msgs.last.content == streamingText.trim();
                  final showStreamingBubble = streamingText.isNotEmpty && !assistantLanded;

                  if (msgs.isEmpty && streamingText.isEmpty && !showOptimistic) {
                    return _buildEmptyState(uid);
                  }
                  _scrollToBottom();

                  final showTyping = isSending && !showStreamingBubble && !assistantLanded;
                  final itemCount = msgs.length +
                      (showOptimistic ? 1 : 0) +
                      (showTyping ? 1 : 0) +
                      (showStreamingBubble ? 1 : 0);

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: itemCount,
                    itemBuilder: (context, i) {
                      if (i < msgs.length) {
                        return ChatBubble(message: msgs[i]);
                      }
                      var idx = i - msgs.length;

                      if (showOptimistic && idx == 0) {
                        return ChatBubble(message: optimistic!);
                      }
                      if (showOptimistic) idx -= 1;

                      if (showStreamingBubble && idx == 0) {
                        return ChatBubble(
                          isStreaming: true,
                          message: ChatMessage(
                            id: 'streaming',
                            role: ChatRole.assistant,
                            content: streamingText,
                            createdAt: DateTime.now(),
                          ),
                        );
                      }
                      return const TypingIndicator();
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                ),
                error: (_, __) => const Center(
                  child: Text('Couldn\'t load messages.',
                      style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins')),
                ),
              ),
            ),
            ChatInputBar(
              isSending: isSending,
              onSend: (text) {
                final history = messages.value ?? const <ChatMessage>[];
                _send(uid, chatId, history, text);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String uid) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6C35DE), AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
          ).animate().fadeIn().scale(delay: 100.ms),
          const SizedBox(height: 20),
          const Text(
            'Hey, I\'m Astra',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ask me anything about movies, or just chat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13.5, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _quickPrompts
                .map((prompt) => _PromptChip(
              label: prompt,
              onTap: () => _send(uid, null, const [], prompt),
            ))
                .toList(),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }
}