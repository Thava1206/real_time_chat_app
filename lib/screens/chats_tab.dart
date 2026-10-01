import 'package:flutter/material.dart';

import '../models/chat_summary.dart';
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
  late final Stream<List<ChatSummary>>? _chats = widget.currentUid == null
      ? null
      : _chatService.watchChats(widget.currentUid!);
  String _query = '';

  bool _matches(ChatSummary chat) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty ||
        chat.otherUser.name.toLowerCase().contains(query) ||
        chat.lastMessage.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              setState(() => _query = value);
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              hintText: 'Search messages',
              prefixIcon: const Icon(Icons.search),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _chats == null
              ? const Center(child: Text('Sign in to view your messages.'))
              : StreamBuilder<List<ChatSummary>>(
                  stream: _chats,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Could not load messages.'),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allChats = snapshot.data ?? [];
                    if (allChats.isEmpty) {
                      return const Center(
                        child: Text(
                          'No conversations yet. Message a contact to start one.',
                        ),
                      );
                    }

                    final chats = allChats.where(_matches).toList();
                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) =>
                          _buildChatTile(context, chats[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatTile(BuildContext context, ChatSummary chat) {
    final other = chat.otherUser;
    final preview = chat.lastSenderId == widget.currentUid
        ? 'You: ${chat.lastMessage}'
        : chat.lastMessage;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: UserAvatar(initials: other.initials, color: other.avatarColor),
      title: Text(
        other.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        preview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.surfaces.mutedText),
      ),
      trailing: Text(
        _formatTime(chat.updatedAt),
        style: TextStyle(fontSize: 12, color: context.surfaces.mutedText),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            currentUid: widget.currentUid!,
            otherUser: other,
            chatService: _chatService,
          ),
        ),
      ),
    );
  }
}

/// Shows the time for today's messages and the date for older ones.
String _formatTime(DateTime? time) {
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
