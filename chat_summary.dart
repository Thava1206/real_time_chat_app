import 'app_user.dart';

/// A conversation as shown in the chat list: the other participant and the
/// most recent message, read from the `chats/{chatId}` document.
class ChatSummary {
  const ChatSummary({
    required this.chatId,
    required this.members,
    required this.lastMessage,
    required this.lastSenderId,
    this._otherUser,
    this.groupName,
    this.isGroup = false,
    this.updatedAt,
  });

  final String chatId;

  /// For groups, this is a display placeholder; use [members] for people.
  final AppUser? _otherUser;
  AppUser get otherUser =>
      _otherUser ??
      AppUser(
        uid: chatId,
        name: groupName ?? 'Group chat',
        email: '',
        avatarColor: AppUser.avatarColorFor(chatId),
      );
  final String? groupName;
  final bool isGroup;
  final List<AppUser> members;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? updatedAt;
}
