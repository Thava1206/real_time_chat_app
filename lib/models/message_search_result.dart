import 'app_user.dart';
import 'chat_message.dart';

enum MessageSearchScope { all, sent, received }

extension MessageSearchScopeLabel on MessageSearchScope {
  String get label => switch (this) {
    MessageSearchScope.all => 'All',
    MessageSearchScope.sent => 'Sent',
    MessageSearchScope.received => 'Received',
  };
}

class MessageSearchResult {
  const MessageSearchResult({
    required this.chatId,
    required this.members,
    required this.message,
    this._otherUser,
    this.groupName,
  });

  final String chatId;

  /// For groups, this placeholder keeps older direct-chat UI callers working.
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
  final List<AppUser> members;
  final ChatMessage message;

  bool get isGroup => groupName != null;
}
