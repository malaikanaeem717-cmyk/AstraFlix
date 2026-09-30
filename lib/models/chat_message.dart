// lib/models/chat_message.dart
// A single message inside an AI chat conversation.

enum ChatRole { user, assistant, system }

ChatRole chatRoleFromString(String value) {
  switch (value) {
    case 'user':
      return ChatRole.user;
    case 'system':
      return ChatRole.system;
    case 'assistant':
    default:
      return ChatRole.assistant;
  }
}

String chatRoleToString(ChatRole role) {
  switch (role) {
    case ChatRole.user:
      return 'user';
    case ChatRole.system:
      return 'system';
    case ChatRole.assistant:
      return 'assistant';
  }
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime createdAt;
  final bool isError;
  // Movies returned by a tool call this turn (search/similar/trending/
  // watchlist/favorites) — rendered as tappable cards below the bubble.
  // Each map: {id, title, posterPath, year, rating}. Not sent back to the
  // LLM (see toApiJson) — purely for the UI.
  final List<Map<String, dynamic>>? movieRefs;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isError = false,
    this.movieRefs,
  });

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? createdAt,
    bool? isError,
    List<Map<String, dynamic>>? movieRefs,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isError: isError ?? this.isError,
      movieRefs: movieRefs ?? this.movieRefs,
    );
  }

  // ─── Firestore ────────────────────────────────────────────────────────────
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'role': chatRoleToString(role),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isError': isError,
      if (movieRefs != null && movieRefs!.isNotEmpty) 'movieRefs': movieRefs,
    };
  }

  factory ChatMessage.fromFirestore(Map<String, dynamic> data) {
    final rawRefs = data['movieRefs'] as List<dynamic>?;
    return ChatMessage(
      id: data['id'] ?? '',
      role: chatRoleFromString(data['role'] ?? 'assistant'),
      content: data['content'] ?? '',
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      isError: data['isError'] ?? false,
      movieRefs: rawRefs?.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  // ─── LLM API payload (role/content pairs only) ───────────────────────────
  Map<String, String> toApiJson() {
    return {
      'role': chatRoleToString(role),
      'content': content,
    };
  }
}