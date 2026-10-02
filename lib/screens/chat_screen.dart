import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_user.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/image_service.dart';
import '../theme/app_theme.dart';
import '../widgets/base64_image.dart';
import '../widgets/photo_source_sheet.dart';
import '../widgets/user_avatar.dart';

/// A direct or group conversation streamed live from Firestore.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.currentUid,
    AppUser? otherUser,
    this.chatId,
    this.groupName,
    this.groupMembers = const [],
    this.chatService,
    this.imageService,
  }) : otherUser =
           otherUser ??
           const AppUser(
             uid: '',
             name: 'Group chat',
             email: '',
             avatarColor: Color(0xFF59647A),
           ),
       assert(otherUser != null || chatId != null);

  final String currentUid;
  final AppUser otherUser;
  final String? chatId;
  final String? groupName;
  final List<AppUser> groupMembers;
  final ChatService? chatService;
  final ImageService? imageService;

  bool get isGroup => chatId != null;

  String get resolvedChatId =>
      chatId ?? ChatService.chatIdFor(currentUid, otherUser.uid);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  late final ChatService _chatService = widget.chatService ?? ChatService();
  late final ImageService _imageService = widget.imageService ?? ImageService();
  late final Stream<List<ChatMessage>> _messages = _chatService.watchMessages(
    widget.resolvedChatId,
  );

  bool _isSendingImage = false;

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
      if (widget.isGroup) {
        await _chatService.sendGroupMessage(
          chatId: widget.resolvedChatId,
          senderId: widget.currentUid,
          text: text,
        );
      } else {
        await _chatService.sendMessage(
          senderId: widget.currentUid,
          recipientId: widget.otherUser.uid,
          text: text,
        );
      }
    } catch (error) {
      if (!mounted) return;
      // Put the text back so the user doesn't lose what they typed.
      if (_controller.text.isEmpty) _controller.text = text;
      _showSendError(error, 'Could not send message.');
    }
  }

  Future<void> _sendImage() async {
    final source = (await showPhotoSourceSheet(context))?.source;
    if (source == null) return;

    setState(() => _isSendingImage = true);
    try {
      final image = await _imageService.pickMessageImage(source);
      if (image == null) return;
      if (widget.isGroup) {
        await _chatService.sendGroupImage(
          chatId: widget.resolvedChatId,
          senderId: widget.currentUid,
          image: image,
        );
      } else {
        await _chatService.sendImage(
          senderId: widget.currentUid,
          recipientId: widget.otherUser.uid,
          image: image,
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showSendError(
        error,
        error is FormatException
            ? 'That file is not a supported image.'
            : 'Could not send image.',
      );
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  void _showSendError(Object error, String fallback) {
    final reason =
        error is FirebaseException && error.code == 'permission-denied'
        ? 'Firestore denied this write. Deploy the latest firestore.rules.'
        : fallback;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(reason)));
  }

  void _openImage(String image) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImage(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.otherUser;
    final memberNames = widget.groupMembers
        .where((member) => member.uid != widget.currentUid)
        .map((member) => member.name)
        .join(', ');
    final groupMemberCount =
        widget.groupMembers.any((member) => member.uid == widget.currentUid)
        ? widget.groupMembers.length
        : widget.groupMembers.length + 1;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            if (!widget.isGroup)
              UserAvatar(
                initials: other.initials,
                color: other.avatarColor,
                photo: other.photo,
                radius: 18,
              )
            else
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.groups_2_outlined,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isGroup
                        ? widget.groupName ?? 'Group chat'
                        : other.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.isGroup
                        ? '$groupMemberCount members${memberNames.isEmpty ? '' : ' · $memberNames'}'
                        : other.email,
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
                      widget.isGroup
                          ? 'Start the conversation!'
                          : 'Say hi to ${other.name}!',
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
                    final image = message.image;
                    if (image != null) {
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: _ImageBubble(
                          image: image,
                          onTap: () => _openImage(image),
                        ),
                      );
                    }
                    final matchingMembers = widget.groupMembers.where(
                      (member) => member.uid == message.senderId,
                    );
                    final sender = matchingMembers.isEmpty
                        ? null
                        : matchingMembers.first;
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isGroup && !isMine)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  sender?.name ?? 'Member',
                                  style: TextStyle(
                                    color: isMine
                                        ? Colors.white70
                                        : Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
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
                  IconButton(
                    tooltip: 'Send image',
                    icon: _isSendingImage
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    onPressed: _isSendingImage ? null : _sendImage,
                  ),
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

/// A sent image in the conversation, sized to fit and tappable to enlarge.
class _ImageBubble extends StatelessWidget {
  const _ImageBubble({required this.image, required this.onTap});

  final String image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.65,
        maxHeight: 320,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: context.surfaces.glassBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: GestureDetector(
          onTap: onTap,
          child: Image(
            image: base64Image(image),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            semanticLabel: 'Photo',
            errorBuilder: (context, _, _) => const SizedBox.square(
              dimension: 120,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows an image full screen with pinch to zoom.
class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image(image: base64Image(image))),
      ),
    );
  }
}
