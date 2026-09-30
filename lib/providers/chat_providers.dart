// lib/providers/chat_providers.dart
// Riverpod wiring for the AI chatbot: session list (sidebar), messages
// stream per session, live streaming-token buffer, and the controller that
// ties the AI service + Firestore together.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/ai_chat_service.dart';
import '../services/ai_tools_service.dart';
import 'app_providers.dart';

// ─── Service singleton ────────────────────────────────────────────────────
final aiChatServiceProvider = Provider<AiChatService>((_) => AiChatService());

// ─── Sidebar: list of the current user's past conversations ─────────────
final chatSessionsProvider = StreamProvider.autoDispose<List<ChatSession>>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) => user == null
        ? Stream.value(<ChatSession>[])
        : ref.read(firestoreServiceProvider).chatSessionsStream(user.uid),
    loading: () => Stream.value(<ChatSession>[]),
    error: (_, __) => Stream.value(<ChatSession>[]),
  );
});

// ─── Which session is currently open (null = fresh/empty chat) ──────────
final activeChatIdProvider = StateProvider.autoDispose<String?>((_) => null);

// ─── Messages for a given session, live from Firestore ──────────────────
final chatMessagesProvider =
StreamProvider.autoDispose.family<List<ChatMessage>, String>((ref, chatId) {
  final auth = ref.watch(authStateProvider);
  return auth.when(
    data: (user) => user == null
        ? Stream.value(<ChatMessage>[])
        : ref.read(firestoreServiceProvider).chatMessagesStream(user.uid, chatId),
    loading: () => Stream.value(<ChatMessage>[]),
    error: (_, __) => Stream.value(<ChatMessage>[]),
  );
});

// ─── Live "typing" buffer while the assistant's reply streams in ────────
// Keyed by chatId so switching sessions never mixes streams up.
final streamingTextProvider =
StateProvider.autoDispose.family<String, String>((_, __) => '');

final isSendingProvider =
StateProvider.autoDispose.family<bool, String>((_, __) => false);

final chatErrorProvider =
StateProvider.autoDispose.family<String?, String>((_, __) => null);

// ─── Controller: orchestrates send → persist user msg → stream AI reply
//     → persist assistant msg ──────────────────────────────────────────────
class ChatController {
  final Ref ref;
  ChatController(this.ref);

  final Set<String> _sendingLocks = {};

  Future<String> startNewSession(String uid) async {
    final session = await ref.read(firestoreServiceProvider).createChatSession(uid);
    ref.read(activeChatIdProvider.notifier).state = session.id;
    return session.id;
  }

  Future<void> sendMessage({
    required String uid,
    required String? chatId,
    required String text,
    required List<ChatMessage> priorHistory,
  }) async {
    final lockKey = chatId ?? 'new:$uid';
    if (_sendingLocks.contains(lockKey)) return;
    _sendingLocks.add(lockKey);

    try {
      await _doSendMessage(uid: uid, chatId: chatId, text: text, priorHistory: priorHistory);
    } finally {
      _sendingLocks.remove(lockKey);
    }
  }

  Future<void> _doSendMessage({
    required String uid,
    required String? chatId,
    required String text,
    required List<ChatMessage> priorHistory,
  }) async {
    final firestore = ref.read(firestoreServiceProvider);
    final aiService = ref.read(aiChatServiceProvider);

    final trimmed = aiService.sanitizeInput(text);
    if (trimmed == null) return;

    String sessionId = chatId ?? '';
    final isFirstMessage = priorHistory.isEmpty;
    if (sessionId.isEmpty) {
      final session = await firestore.createChatSession(uid);
      sessionId = session.id;
      ref.read(activeChatIdProvider.notifier).state = sessionId;
    }

    ref.read(chatErrorProvider(sessionId).notifier).state = null;

    final userMessage = ChatMessage(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    try {
      await firestore.addChatMessage(uid, sessionId, userMessage);
      await firestore.touchChatSession(
        uid,
        sessionId,
        lastMessage: trimmed,
        autoTitle: isFirstMessage ? aiService.suggestTitle(trimmed) : null,
      );
    } catch (_) {
      ref.read(chatErrorProvider(sessionId).notifier).state =
      'Couldn\'t save your message. Check your connection and try again.';
      return;
    }

    ref.read(isSendingProvider(sessionId).notifier).state = true;
    ref.read(streamingTextProvider(sessionId).notifier).state = '';

    final history = [...priorHistory, userMessage];

    final tools = AiToolsService(uid: uid);

    // Capture any movies a tool call surfaced this turn, so they can be
    // shown as tappable cards under the assistant's reply.
    final collectedMovies = <int, Map<String, dynamic>>{};
    Future<Map<String, dynamic>> toolExecutorWithCapture(
        String toolName,
        Map<String, dynamic> args,
        ) async {
      final result = await tools.execute(toolName, args);
      final results = result['results'];
      if (results is List) {
        for (final m in results) {
          if (m is Map<String, dynamic> && m['id'] is int) {
            collectedMovies[m['id'] as int] = m;
          }
        }
      }
      return result;
    }

    try {
      final buffer = StringBuffer();
      await for (final chunk in aiService.streamReply(
        history,
        toolExecutor: toolExecutorWithCapture,
      )) {
        buffer.write(chunk);
        ref.read(streamingTextProvider(sessionId).notifier).state = buffer.toString();
      }

      final finalContent = buffer.toString().trim();
      ref.read(streamingTextProvider(sessionId).notifier).state = '';

      final assistantMessage = ChatMessage(
        id: 'a_${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.assistant,
        content: finalContent,
        createdAt: DateTime.now(),
        movieRefs: collectedMovies.values.take(10).toList(),
      );
      await firestore.addChatMessage(uid, sessionId, assistantMessage);
      await firestore.touchChatSession(uid, sessionId, lastMessage: assistantMessage.content);
    } catch (e) {
      final errorText = e is AiChatException ? e.message : 'Something went wrong. Please try again.';
      ref.read(chatErrorProvider(sessionId).notifier).state = errorText;

      final errorMessage = ChatMessage(
        id: 'a_${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.assistant,
        content: errorText,
        createdAt: DateTime.now(),
        isError: true,
      );
      try {
        await firestore.addChatMessage(uid, sessionId, errorMessage);
      } catch (_) {}
    } finally {
      ref.read(streamingTextProvider(sessionId).notifier).state = '';
      ref.read(isSendingProvider(sessionId).notifier).state = false;
    }
  }

  Future<void> deleteSession(String uid, String chatId) async {
    await ref.read(firestoreServiceProvider).deleteChatSession(uid, chatId);
    if (ref.read(activeChatIdProvider) == chatId) {
      ref.read(activeChatIdProvider.notifier).state = null;
    }
  }

  Future<void> renameSession(String uid, String chatId, String title) async {
    await ref.read(firestoreServiceProvider).renameChatSession(uid, chatId, title);
  }
}

final chatControllerProvider = Provider<ChatController>((ref) => ChatController(ref));