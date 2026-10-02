import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/chat_summary.dart';
import '../models/message_search_result.dart';
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

  /// Longest base64 image the Firestore rules accept. Leaves headroom under
  /// Firestore's 1 MiB document limit.
  static const maxImageLength = 900000;

  /// Chat-list preview shown for an image message.
  static const imagePreview = '📷 Photo';

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

  /// Searches message history across this user's conversations. Filtering is
  /// performed locally so partial-text matching works without new indexes or
  /// changes to the stored message schema.
  Future<List<MessageSearchResult>> searchMessages({
    required String uid,
    required String query,
    MessageSearchScope scope = MessageSearchScope.all,
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];

    final chatSnapshot = await _chats
        .where('participants', arrayContains: uid)
        .get();
    String otherUid(Map<String, dynamic> data) => (data['participants'] as List)
        .cast<String>()
        .firstWhere((id) => id != uid, orElse: () => uid);
    final profiles = await _userService.fetchUsers(
      chatSnapshot.docs.map((doc) => otherUid(doc.data())).toList(),
    );
    final results = <MessageSearchResult>[];

    for (final chat in chatSnapshot.docs) {
      final otherUser = profiles[otherUid(chat.data())];
      if (otherUser == null) continue;
      final messages = await _messages(chat.id).orderBy('createdAt').get();
      for (final document in messages.docs) {
        final message = ChatMessage.fromFirestore(document);
        final isSent = message.senderId == uid;
        final matchesScope = switch (scope) {
          MessageSearchScope.all => true,
          MessageSearchScope.sent => isSent,
          MessageSearchScope.received => !isSent,
        };
        if (matchesScope &&
            message.text.toLowerCase().contains(normalizedQuery)) {
          results.add(
            MessageSearchResult(
              chatId: chat.id,
              otherUser: otherUser,
              message: message,
            ),
          );
        }
      }
    }

    results.sort((a, b) {
      final aTime = a.message.createdAt;
      final bTime = b.message.createdAt;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return results;
  }

  /// Sends a text message.
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

    return _send(
      ChatMessage(id: '', senderId: senderId, text: trimmed),
      recipientId: recipientId,
      preview: trimmed,
    );
  }

  /// Sends a base64-encoded [image] as its own message.
  Future<void> sendImage({
    required String senderId,
    required String recipientId,
    required String image,
  }) {
    if (image.isEmpty) {
      throw ArgumentError.value(image, 'image', 'Image is empty');
    }
    if (image.length > maxImageLength) {
      throw ArgumentError.value(image.length, 'image', 'Image is too large');
    }

    return _send(
      ChatMessage(id: '', senderId: senderId, text: '', image: image),
      recipientId: recipientId,
      preview: imagePreview,
    );
  }

  /// Adds [message] and updates the chat's last-message preview together.
  Future<void> _send(
    ChatMessage message, {
    required String recipientId,
    required String preview,
  }) {
    final senderId = message.senderId;
    if (senderId == recipientId) {
      throw ArgumentError.value(
        recipientId,
        'recipientId',
        'Cannot message self',
      );
    }

    final chatId = chatIdFor(senderId, recipientId);
    return (_firestore.batch()
          ..set(_messages(chatId).doc(), message.toFirestore())
          ..set(_chats.doc(chatId), {
            'participants': _participants(senderId, recipientId),
            'lastMessage': preview,
            'lastSenderId': senderId,
            'updatedAt': FieldValue.serverTimestamp(),
          }))
        .commit();
  }
}
