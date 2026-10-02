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
    required this.otherUser,
    required this.message,
  });

  final String chatId;
  final AppUser otherUser;
  final ChatMessage message;
}
