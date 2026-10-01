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

  late ChatService chatService;

  setUp(() => chatService = ChatService(firestore: FakeFirebaseFirestore()));

  Finder messageBubbles() =>
      find.descendant(of: find.byType(ListView), matching: find.byType(Text));

  Future<void> pumpChat(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          currentUid: 'me',
          otherUser: maya,
          chatService: chatService,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> sendFromUi(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the contact name and email', (tester) async {
    await pumpChat(tester);

    expect(find.widgetWithText(AppBar, 'Maya Chen'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'maya@example.com'), findsOneWidget);
  });

  testWidgets('shows a prompt when there are no messages yet', (tester) async {
    await pumpChat(tester);

    expect(find.text('Say hi to Maya Chen!'), findsOneWidget);
  });

  testWidgets('shows messages already stored in Firestore', (tester) async {
    await chatService.sendMessage(
      senderId: 'maya',
      recipientId: 'me',
      text: 'Are you there?',
    );
    await pumpChat(tester);

    expect(find.text('Are you there?'), findsOneWidget);
  });

  testWidgets('send button saves the message and clears the input', (
    tester,
  ) async {
    await pumpChat(tester);

    await sendFromUi(tester, 'Hello from the test');

    expect(find.text('Hello from the test'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    final messages = await chatService
        .watchMessages(ChatService.chatIdFor('me', 'maya'))
        .first;
    expect(messages.single.text, 'Hello from the test');
    expect(messages.single.senderId, 'me');
  });

  testWidgets('messages from the other user appear live', (tester) async {
    await pumpChat(tester);

    await chatService.sendMessage(
      senderId: 'maya',
      recipientId: 'me',
      text: 'Just replied',
    );
    await tester.pumpAndSettle();

    expect(find.text('Just replied'), findsOneWidget);
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

  testWidgets('blank messages are not sent', (tester) async {
    await pumpChat(tester);
    await sendFromUi(tester, 'First');
    final bubbleCount = messageBubbles().evaluate().length;

    await sendFromUi(tester, '   ');

    expect(messageBubbles().evaluate().length, bubbleCount);
  });

  testWidgets('sent messages are trimmed', (tester) async {
    await pumpChat(tester);

    await sendFromUi(tester, '  padded  ');

    expect(find.text('padded'), findsOneWidget);
  });
}
