import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar.dart';

/// A one-to-one conversation with [otherUser], streamed live from Firestore.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.currentUid,
    required this.otherUser,
    this.chatService,
  });

  final String currentUid;
  final AppUser otherUser;
  final ChatService? chatService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  late final ChatService _chatService = widget.chatService ?? ChatService();
  late final Stream<List<ChatMessage>> _messages = _chatService.watchMessages(
    ChatService.chatIdFor(widget.currentUid, widget.otherUser.uid),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await _chatService.sendMessage(
        senderId: widget.currentUid,
        recipientId: widget.otherUser.uid,
        text: text,
      );
    } catch (error) {
      if (!mounted) return;
      // Put the text back so the user doesn't lose what they typed.
      if (_controller.text.isEmpty) _controller.text = text;
      final reason =
          error is FirebaseException && error.code == 'permission-denied'
          ? 'Firestore denied this write. Deploy the latest firestore.rules.'
          : 'Could not send message.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(reason)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.otherUser;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              initials: other.initials,
              color: other.avatarColor,
              radius: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(other.name, style: const TextStyle(fontSize: 16)),
                  Text(
                    other.email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.surfaces.mutedText,
                    ),
                  ),
                ],
              ),
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
                if (snapshot.hasError) {
                  return const Center(child: Text('Could not load messages.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hi to ${other.name}!',
                      style: TextStyle(color: context.surfaces.mutedText),
                    ),
                  );
                }

                // Reversed so the list starts at the bottom and new messages
                // stay in view as they arrive.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
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
                          color: isMine
                              ? context.surfaces.sentBubble
                              : context.surfaces.receivedBubble,
                          border: Border.all(
                            color: context.surfaces.glassBorder,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          message.text,
                          style: TextStyle(
                            color: isMine
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
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
              decoration: BoxDecoration(
                color: context.surfaces.surface,
                border: Border(
                  top: BorderSide(color: context.surfaces.glassBorder),
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                          ChatService.maxMessageLength,
                        ),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Type a message',
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      side: context.surfaces.isGlass
                          ? const BorderSide(
                              color: Color(0xA6FFF2A8),
                              width: 1.2,
                            )
                          : null,
                    ),
                    icon: const Icon(Icons.send, shadows: []),
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
