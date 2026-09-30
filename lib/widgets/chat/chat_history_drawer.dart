// lib/widgets/chat/chat_history_drawer.dart
// Left-hand sidebar listing all of the user's past conversations —
// the same pattern as ChatGPT / Claude's history panel.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/chat_session.dart';
import '../../providers/chat_providers.dart';
import '../../theme/app_theme.dart';

class ChatHistoryDrawer extends ConsumerWidget {
  final String uid;
  const ChatHistoryDrawer({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(chatSessionsProvider);
    final activeId = ref.watch(activeChatIdProvider);

    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Chats',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'New chat',
                    icon: const Icon(Icons.add_comment_outlined, color: AppColors.textSecondary),
                    onPressed: () {
                      ref.read(activeChatIdProvider.notifier).state = null;
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFF1F1F1F)),
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const _EmptyHistory();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: sessions.length,
                    itemBuilder: (context, i) {
                      final session = sessions[i];
                      final isActive = session.id == activeId;
                      return _SessionTile(
                        session: session,
                        isActive: isActive,
                        onTap: () {
                          ref.read(activeChatIdProvider.notifier).state = session.id;
                          Navigator.of(context).pop();
                        },
                        onDelete: () async {
                          final confirmed = await _confirmDelete(context);
                          if (confirmed == true) {
                            await ref.read(chatControllerProvider).deleteSession(uid, session.id);
                          }
                        },
                        onRename: (title) =>
                            ref.read(chatControllerProvider).renameSession(uid, session.id, title),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const _EmptyHistory(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete chat?', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins')),
        content: const Text(
          'This conversation will be permanently deleted.',
          style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final ChatSession session;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  const _SessionTile({
    required this.session,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceVariant : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 18,
          color: isActive ? AppColors.primary : AppColors.textMuted,
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 13.5,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            fontFamily: 'Poppins',
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz, color: AppColors.textMuted, size: 18),
          color: AppColors.surfaceVariant,
          onSelected: (value) {
            if (value == 'delete') onDelete();
            if (value == 'rename') _showRenameDialog(context);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename', style: TextStyle(color: AppColors.textPrimary))),
            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Rename chat', style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins')),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Chat title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              onRename(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textHint, size: 36),
          SizedBox(height: 12),
          Text(
            'No conversations yet.\nStart chatting with Astra!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }
}
