import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/conversation.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

/// A single conversation between [currentUid] and [other], stored in Firestore.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.currentUid,
    required this.other,
    this.chatService,
  });

  final String currentUid;
  final AppUser other;
  final ChatService? chatService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  late final ChatService _chatService = widget.chatService ?? ChatService();
  late final Stream<List<ChatMessage>> _messages = _chatService.watchMessages(
    ChatService.conversationId(widget.currentUid, widget.other.uid),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _chatService.sendMessage(
      senderId: widget.currentUid,
      recipientId: widget.other.uid,
      text: text,
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.other;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.inkRaised,
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              initials: chat.initials,
              color: chat.avatarColor,
              radius: 18,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(chat.name, style: const TextStyle(fontSize: 16))],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messages,
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <ChatMessage>[];
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == widget.currentUid;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? AppColors.plum : AppColors.inkHigh,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(message.text),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              color: AppColors.inkRaised,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        filled: true,
                        fillColor: AppColors.inkHigh,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.ink,
                    ),
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
