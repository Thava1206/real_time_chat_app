import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_message.dart';
import '../models/chat_summary.dart';
import '../models/message_search_result.dart';
import '../models/app_user.dart';
import 'user_service.dart';

/// Sends and streams direct and group conversations in the `chats` collection.
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
  Stream<List<ChatSummary>> watchChats(
    String uid,
  ) => _chats.where('participants', arrayContains: uid).snapshots().asyncMap((
    snapshot,
  ) async {
    final profiles = await _userService.fetchUsers(
      snapshot.docs
          .expand((doc) => (doc.data()['participants'] as List).cast<String>())
          .toList(),
    );

    final chats = <ChatSummary>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final participantIds = (data['participants'] as List).cast<String>();
      final members = participantIds
          .map((id) => profiles[id])
          .whereType<AppUser>()
          .toList();
      final isGroup = data['type'] == 'group' || participantIds.length > 2;
      final otherUser = isGroup
          ? null
          : profiles[participantIds.firstWhere(
              (id) => id != uid,
              orElse: () => uid,
            )];
      if (!isGroup && otherUser == null) continue;
      chats.add(
        ChatSummary(
          chatId: doc.id,
          members: members,
          otherUser: otherUser,
          isGroup: isGroup,
          groupName: isGroup ? data['name'] as String? ?? 'Group chat' : null,
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
    final profiles = await _userService.fetchUsers(
      chatSnapshot.docs
          .expand((doc) => (doc.data()['participants'] as List).cast<String>())
          .toList(),
    );
    final results = <MessageSearchResult>[];

    for (final chat in chatSnapshot.docs) {
      final data = chat.data();
      final participantIds = (data['participants'] as List).cast<String>();
      final members = participantIds
          .map((id) => profiles[id])
          .whereType<AppUser>()
          .toList();
      final isGroup = data['type'] == 'group' || participantIds.length > 2;
      final otherUser = isGroup
          ? null
          : profiles[participantIds.firstWhere(
              (id) => id != uid,
              orElse: () => uid,
            )];
      if (!isGroup && otherUser == null) continue;
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
              members: members,
              otherUser: otherUser,
              groupName: isGroup
                  ? data['name'] as String? ?? 'Group chat'
                  : null,
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
            'type': 'direct',
            'lastMessage': trimmed,
            'lastSenderId': senderId,
            'updatedAt': FieldValue.serverTimestamp(),
          }))
        .commit();
  }

  /// Creates a named group with the creator and at least two other members.
  /// Returns the generated conversation id.
  Future<String> createGroupChat({
    required String creatorId,
    required String name,
    required List<String> participantIds,
  }) async {
    final trimmedName = name.trim();
    final participants = {...participantIds, creatorId}.toList()..sort();
    if (trimmedName.isEmpty || trimmedName.length > 50) {
      throw ArgumentError.value(
        name,
        'name',
        'Group name must be 1–50 characters',
      );
    }
    if (participants.length < 3) {
      throw ArgumentError.value(
        participantIds,
        'participantIds',
        'Select at least two other people for a group chat',
      );
    }

    final chat = _chats.doc();
    final createdMessage = ChatMessage(
      id: '',
      senderId: creatorId,
      text: 'Created the group “$trimmedName”',
    );
    await (_firestore.batch()
          ..set(chat, {
            'participants': participants,
            'type': 'group',
            'name': trimmedName,
            'createdBy': creatorId,
            'lastMessage': createdMessage.text,
            'lastSenderId': creatorId,
            'updatedAt': FieldValue.serverTimestamp(),
          })
          ..set(_messages(chat.id).doc(), createdMessage.toFirestore()))
        .commit();
    return chat.id;
  }

  /// Sends a message to an existing group and refreshes its list preview.
  Future<void> sendGroupMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) {
    final trimmed = text.trim();
    _validateMessage(trimmed, text);
    final message = ChatMessage(id: '', senderId: senderId, text: trimmed);
    return (_firestore.batch()
          ..set(_messages(chatId).doc(), message.toFirestore())
          ..update(_chats.doc(chatId), {
            'lastMessage': trimmed,
            'lastSenderId': senderId,
            'updatedAt': FieldValue.serverTimestamp(),
          }))
        .commit();
  }

  static void _validateMessage(String trimmed, String original) {
    if (trimmed.isEmpty) {
      throw ArgumentError.value(original, 'text', 'Message is empty');
    }
    if (trimmed.length > maxMessageLength) {
      throw ArgumentError.value(original, 'text', 'Message is too long');
    }
  }
}
