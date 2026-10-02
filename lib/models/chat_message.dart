import 'package:cloud_firestore/cloud_firestore.dart';

/// A single message stored at `chats/{chatId}/messages/{id}`.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.image,
    this.createdAt,
  });

  final String id;
  final String senderId;

  /// Empty for image messages.
  final String text;

  /// Base64-encoded image, or null for a text message.
  final String? image;

  /// Null until the server timestamp for a just-sent message is confirmed.
  final DateTime? createdAt;

  factory ChatMessage.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      text: data['text'] as String? ?? '',
      image: data['image'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'text': text,
    if (image != null) 'image': image,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
