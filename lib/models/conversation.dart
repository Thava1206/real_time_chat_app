import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_user.dart';

/// A one-to-one conversation, stored at `conversations/{id}` in Firestore.
class Conversation {
  const Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderId,
    this.updatedAt,
  });

  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? updatedAt;

  String otherUid(String myUid) =>
      participants.firstWhere((p) => p != myUid, orElse: () => myUid);

  factory Conversation.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return Conversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] as List? ?? []),
      lastMessage: data['lastMessage'] as String? ?? '',
      lastSenderId: data['lastSenderId'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A conversation paired with the profile of the other participant.
class ConversationPreview {
  const ConversationPreview({required this.conversation, required this.other});

  final Conversation conversation;
  final AppUser other;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
  });

  final String id;
  final String senderId;
  final String text;

  factory ChatMessage.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
    );
  }
}
