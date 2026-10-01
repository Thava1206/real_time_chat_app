import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/chat_summary.dart';
import 'user_service.dart';

/// Sends and streams one-to-one messages stored in the `chats` collection.
///
/// Each conversation lives at `chats/{chatId}`, where the id is both user ids
/// sorted and joined with `_`, so either participant opens the same chat.
class ChatService {
  ChatService({FirebaseFirestore? firestore, UserService? userService})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _userService = userService ?? UserService(firestore: firestore);

  /// Longest message the Firestore rules accept.
  static const maxMessageLength = 1000;

  final FirebaseFirestore _firestore;
  final UserService _userService;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection('messages');

  static String chatIdFor(String uid, String otherUid) =>
      _participants(uid, otherUid).join('_');

  static List<String> _participants(String uid, String otherUid) =>
      [uid, otherUid]..sort();

  /// Emits the conversation's messages, oldest first, whenever they change.
  Stream<List<ChatMessage>> watchMessages(String chatId) => _messages(chatId)
      .orderBy('createdAt')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ChatMessage.fromFirestore).toList());

  /// Emits the user's conversations, most recently active first.
  Stream<List<ChatSummary>> watchChats(String uid) => _chats
      .where('participants', arrayContains: uid)
      .snapshots()
      .asyncMap((snapshot) async {
        String otherUid(Map<String, dynamic> data) =>
            (data['participants'] as List).cast<String>().firstWhere(
              (id) => id != uid,
              orElse: () => uid,
            );

        final profiles = await _userService.fetchUsers(
          snapshot.docs.map((doc) => otherUid(doc.data())).toList(),
        );

        final chats = <ChatSummary>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final otherUser = profiles[otherUid(data)];
          if (otherUser == null) continue;
          chats.add(
            ChatSummary(
              chatId: doc.id,
              otherUser: otherUser,
              lastMessage: data['lastMessage'] as String? ?? '',
              lastSenderId: data['lastSenderId'] as String? ?? '',
              updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
            ),
          );
        }
        // Sorted here rather than in the query to avoid needing a composite
        // index. A just-sent chat has no server time yet, so it goes first.
        chats.sort((a, b) {
          if (a.updatedAt == null) return -1;
          if (b.updatedAt == null) return 1;
          return b.updatedAt!.compareTo(a.updatedAt!);
        });
        return chats;
      });

  /// Adds the message and updates the chat's last-message preview together.
  Future<void> sendMessage({
    required String senderId,
    required String recipientId,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'Message is empty');
    }
    if (trimmed.length > maxMessageLength) {
      throw ArgumentError.value(text, 'text', 'Message is too long');
    }
    if (senderId == recipientId) {
      throw ArgumentError.value(
        recipientId,
        'recipientId',
        'Cannot message self',
      );
    }

    final chatId = chatIdFor(senderId, recipientId);
    final message = ChatMessage(id: '', senderId: senderId, text: trimmed);

    return (_firestore.batch()
          ..set(_messages(chatId).doc(), message.toFirestore())
          ..set(_chats.doc(chatId), {
            'participants': _participants(senderId, recipientId),
            'lastMessage': trimmed,
            'lastSenderId': senderId,
            'updatedAt': FieldValue.serverTimestamp(),
          }))
        .commit();
  }
}
