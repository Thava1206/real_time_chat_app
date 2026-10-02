import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/services/chat_service.dart';
import 'package:real_time_chat_app/services/user_service.dart';
import 'package:real_time_chat_app/models/message_search_result.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ChatService chatService;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    chatService = ChatService(firestore: firestore);
    final userService = UserService(firestore: firestore);
    await userService.createProfile(
      uid: 'alice',
      name: 'Alice Wong',
      email: 'alice@example.com',
    );
    await userService.createProfile(
      uid: 'bob',
      name: 'Bob Stone',
      email: 'bob@example.com',
    );
    await userService.createProfile(
      uid: 'cara',
      name: 'Cara Diaz',
      email: 'cara@example.com',
    );
  });

  test('chatIdFor is the same whichever user starts the chat', () {
    expect(ChatService.chatIdFor('bob', 'alice'), 'alice_bob');
    expect(ChatService.chatIdFor('alice', 'bob'), 'alice_bob');
  });

  test('sendMessage stores the message and the chat preview', () async {
    await chatService.sendMessage(
      senderId: 'bob',
      recipientId: 'alice',
      text: '  Hi Alice  ',
    );

    final chat = await firestore.collection('chats').doc('alice_bob').get();
    expect(chat.data()!['participants'], ['alice', 'bob']);
    expect(chat.data()!['lastMessage'], 'Hi Alice');
    expect(chat.data()!['lastSenderId'], 'bob');
    expect(chat.data()!['updatedAt'], isNotNull);

    final messages = await chatService.watchMessages('alice_bob').first;
    expect(messages, hasLength(1));
    expect(messages.single.text, 'Hi Alice');
    expect(messages.single.senderId, 'bob');
    expect(messages.single.createdAt, isNotNull);
  });

  test('both users see the conversation in order', () async {
    await chatService.sendMessage(
      senderId: 'alice',
      recipientId: 'bob',
      text: 'First',
    );
    await chatService.sendMessage(
      senderId: 'bob',
      recipientId: 'alice',
      text: 'Second',
    );

    final chatId = ChatService.chatIdFor('alice', 'bob');
    final messages = await chatService.watchMessages(chatId).first;
    expect(messages.map((m) => m.text), ['First', 'Second']);
    expect(messages.map((m) => m.senderId), ['alice', 'bob']);
  });

  test('watchChats lists the other participant and last message', () async {
    await chatService.sendMessage(
      senderId: 'alice',
      recipientId: 'bob',
      text: 'Hello Bob',
    );
    await chatService.sendMessage(
      senderId: 'cara',
      recipientId: 'alice',
      text: 'Hey from Cara',
    );

    final aliceChats = await chatService.watchChats('alice').first;
    expect(
      aliceChats.map((c) => c.otherUser.name),
      unorderedEquals(['Bob Stone', 'Cara Diaz']),
    );

    final bobChats = await chatService.watchChats('bob').first;
    expect(bobChats.single.otherUser.name, 'Alice Wong');
    expect(bobChats.single.lastMessage, 'Hello Bob');
    expect(bobChats.single.lastSenderId, 'alice');
  });

  test('searchMessages searches all, sent, and received messages', () async {
    await chatService.sendMessage(
      senderId: 'alice',
      recipientId: 'bob',
      text: 'Project update from Alice',
    );
    await chatService.sendMessage(
      senderId: 'bob',
      recipientId: 'alice',
      text: 'Project update from Bob',
    );
    await chatService.sendMessage(
      senderId: 'cara',
      recipientId: 'alice',
      text: 'Unrelated note',
    );

    final all = await chatService.searchMessages(
      uid: 'alice',
      query: 'project UPDATE',
    );
    final sent = await chatService.searchMessages(
      uid: 'alice',
      query: 'project',
      scope: MessageSearchScope.sent,
    );
    final received = await chatService.searchMessages(
      uid: 'alice',
      query: 'project',
      scope: MessageSearchScope.received,
    );

    expect(all, hasLength(2));
    expect(sent.single.message.senderId, 'alice');
    expect(received.single.message.senderId, 'bob');
    expect(received.single.otherUser.name, 'Bob Stone');
  });

  test('rejects empty, overly long and self messages', () {
    expect(
      () => chatService.sendMessage(
        senderId: 'alice',
        recipientId: 'bob',
        text: '   ',
      ),
      throwsArgumentError,
    );
    expect(
      () => chatService.sendMessage(
        senderId: 'alice',
        recipientId: 'bob',
        text: 'x' * (ChatService.maxMessageLength + 1),
      ),
      throwsArgumentError,
    );
    expect(
      () => chatService.sendMessage(
        senderId: 'alice',
        recipientId: 'alice',
        text: 'Hi me',
      ),
      throwsArgumentError,
    );
  });

  test('sendImage stores the image with a photo preview', () async {
    await chatService.sendImage(
      senderId: 'alice',
      recipientId: 'bob',
      image: 'aW1hZ2U=',
    );

    final chat = await firestore.collection('chats').doc('alice_bob').get();
    expect(chat.data()!['lastMessage'], ChatService.imagePreview);

    final message = (await chatService.watchMessages('alice_bob').first).single;
    expect(message.image, 'aW1hZ2U=');
    expect(message.text, isEmpty);
    expect(message.senderId, 'alice');
  });

  test('text messages are stored without an image field', () async {
    await chatService.sendMessage(
      senderId: 'alice',
      recipientId: 'bob',
      text: 'Hi',
    );

    final messages = await firestore
        .collection('chats/alice_bob/messages')
        .get();
    expect(messages.docs.single.data().containsKey('image'), isFalse);
  });

  test('rejects empty, oversized and self images', () {
    expect(
      () => chatService.sendImage(
        senderId: 'alice',
        recipientId: 'bob',
        image: '',
      ),
      throwsArgumentError,
    );
    expect(
      () => chatService.sendImage(
        senderId: 'alice',
        recipientId: 'bob',
        image: 'a' * (ChatService.maxImageLength + 1),
      ),
      throwsArgumentError,
    );
    expect(
      () => chatService.sendImage(
        senderId: 'alice',
        recipientId: 'alice',
        image: 'aW1hZ2U=',
      ),
      throwsArgumentError,
    );
  });
}
