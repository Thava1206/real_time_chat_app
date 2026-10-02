import 'app_user.dart';

/// A conversation as shown in the chat list: the other participant and the
/// most recent message, read from the `chats/{chatId}` document.
class ChatSummary {
  const ChatSummary({
    required this.chatId,
    required this.otherUser,
    required this.lastMessage,
    required this.lastSenderId,
    this.updatedAt,
  });

  final String chatId;
  final AppUser otherUser;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? updatedAt;
}
