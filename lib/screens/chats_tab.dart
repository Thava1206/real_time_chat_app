import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen.dart';

class ChatsTab extends StatefulWidget {
  const ChatsTab({super.key, this.currentUid, this.chatService});

  final String? currentUid;
  final ChatService? chatService;

  @override
  State<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends State<ChatsTab> {
  late final ChatService _chatService = widget.chatService ?? ChatService();
  late final Stream<List<ConversationPreview>>? _conversations =
      widget.currentUid == null
      ? null
      : _chatService.watchConversations(widget.currentUid!);

  static String _formatTime(DateTime? time) {
    if (time == null) return '';
    final local = time.toLocal();
    final now = DateTime.now();
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
    }
    return '${local.month}/${local.day}/${local.year % 100}';
  }

  Widget _buildList(String uid) {
    return StreamBuilder<List<ConversationPreview>>(
      stream: _conversations,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load conversations.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final previews = snapshot.data ?? [];
        if (previews.isEmpty) {
          return const Center(
            child: Text('No conversations yet. Message a contact to start.'),
          );
        }

        return ListView.builder(
          itemCount: previews.length,
          itemBuilder: (context, index) {
            final conversation = previews[index].conversation;
            final other = previews[index].other;
            final prefix = conversation.lastSenderId == uid ? 'You: ' : '';
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: UserAvatar(
                initials: other.initials,
                color: other.avatarColor,
              ),
              title: Text(
                other.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '$prefix${conversation.lastMessage}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              trailing: Text(
                _formatTime(conversation.updatedAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    currentUid: uid,
                    other: other,
                    chatService: widget.chatService,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.currentUid;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search messages',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.inkHigh,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: AppColors.gold),
              ),
            ),
          ),
        ),
        Expanded(
          child: uid == null
              ? const Center(child: Text('Sign in to view your messages.'))
              : _buildList(uid),
        ),
      ],
    );
  }
}
