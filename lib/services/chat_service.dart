import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/conversation.dart';

/// Reads and writes conversations in the `conversations` Firestore collection.
class ChatService {
  ChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  /// Same id for both users so a pair of people only ever has one conversation.
  static String conversationId(String a, String b) {
    final sorted = [a, b]..sort();
    return sorted.join('_');
  }

  /// Emits the user's conversations, newest first, with the other person's
  /// profile attached. Conversations whose other user is missing are skipped.
  Stream<List<ConversationPreview>> watchConversations(String uid) =>
      _conversations
          .where('participants', arrayContains: uid)
          .snapshots()
          .asyncMap((snapshot) async {
            final conversations = snapshot.docs
                .map(Conversation.fromFirestore)
                .toList();
            conversations.sort(
              (a, b) => (b.updatedAt ?? DateTime.now()).compareTo(
                a.updatedAt ?? DateTime.now(),
              ),
            );

            final previews = <ConversationPreview>[];
            for (final conversation in conversations) {
              final otherDoc = await _firestore
                  .collection('users')
                  .doc(conversation.otherUid(uid))
                  .get();
              if (!otherDoc.exists) continue;
              previews.add(
                ConversationPreview(
                  conversation: conversation,
                  other: AppUser.fromFirestore(otherDoc),
                ),
              );
            }
            return previews;
          });

  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      _conversations
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map((s) => s.docs.map(ChatMessage.fromFirestore).toList());

  /// Adds the message and updates the conversation summary, creating the
  /// conversation on first use.
  Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final ref = _conversations.doc(conversationId(senderId, recipientId));
    final batch = _firestore.batch();
    batch.set(ref, {
      'participants': [senderId, recipientId],
      'lastMessage': trimmed,
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(ref.collection('messages').doc(), {
      'senderId': senderId,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
