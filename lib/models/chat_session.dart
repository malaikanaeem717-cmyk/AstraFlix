// lib/models/chat_session.dart
// A single conversation thread, shown in the chat history sidebar —
// same idea as ChatGPT/Claude's left-hand conversation list.

class ChatSession {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatSession({
    required this.id,
    this.title = 'New chat',
    this.lastMessage = '',
    this.createdAt,
    this.updatedAt,
  });

  ChatSession copyWith({
    String? title,
    String? lastMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
        'title': title,
        'lastMessage': lastMessage,
      };

  factory ChatSession.fromFirestore(String id, Map<String, dynamic> data) {
    return ChatSession(
      id: id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title']
          : 'New chat',
      lastMessage: data['lastMessage'] ?? '',
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    // Firestore Timestamp has a toDate() method.
    try {
      return value.toDate();
    } catch (_) {
      return null;
    }
  }
}
