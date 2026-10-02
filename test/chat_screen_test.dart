import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/models/app_user.dart';
import 'package:real_time_chat_app/screens/chat_screen.dart';
import 'package:real_time_chat_app/services/chat_service.dart';
import 'package:real_time_chat_app/theme/app_theme.dart';

void main() {
  const maya = AppUser(
    uid: 'maya',
    name: 'Maya Chen',
    email: 'maya@example.com',
    avatarColor: AppColors.plum,
  );

  late FakeFirebaseFirestore firestore;
  late ChatService chatService;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    chatService = ChatService(firestore: firestore);
  });

  Future<void> pumpChat(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          currentUid: 'me',
          other: maya,
          chatService: chatService,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the contact name', (tester) async {
    await pumpChat(tester);

    expect(find.widgetWithText(AppBar, 'Maya Chen'), findsOneWidget);
  });

  testWidgets('shows stored messages', (tester) async {
    await chatService.sendMessage(
      senderId: 'maya',
      recipientId: 'me',
      text: 'Stored hello',
    );
    await pumpChat(tester);

    expect(find.text('Stored hello'), findsOneWidget);
  });

  testWidgets('send button stores the message and clears the input', (
    tester,
  ) async {
    await pumpChat(tester);

    await tester.enterText(find.byType(TextField), 'Hello from the test');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('Hello from the test'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);

    final conversation = await firestore
        .collection('conversations')
        .doc(ChatService.conversationId('me', 'maya'))
        .get();
    expect(conversation.data()!['lastMessage'], 'Hello from the test');
  });

  testWidgets('pressing enter on the keyboard sends the message', (
    tester,
  ) async {
    await pumpChat(tester);

    await tester.enterText(find.byType(TextField), 'Sent with enter');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('Sent with enter'), findsOneWidget);
  });

  testWidgets('blank messages are not stored', (tester) async {
    await pumpChat(tester);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    final conversations = await firestore.collection('conversations').get();
    expect(conversations.docs, isEmpty);
  });

  testWidgets('sent messages are trimmed', (tester) async {
    await pumpChat(tester);

    await tester.enterText(find.byType(TextField), '  padded  ');
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text('padded'), findsOneWidget);
  });
}
