import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/data/sample_data.dart';
import 'package:real_time_chat_app/screens/chat_screen.dart';

void main() {
  final onlineChat = sampleChats.firstWhere((c) => c.isOnline);
  final offlineChat = sampleChats.firstWhere((c) => !c.isOnline);

  Finder messageBubbles() =>
      find.descendant(of: find.byType(ListView), matching: find.byType(Text));

  Future<void> pumpChat(WidgetTester tester, SampleChat chat) =>
      tester.pumpWidget(MaterialApp(home: ChatScreen(chat: chat)));

  testWidgets('shows the contact name and online status', (tester) async {
    await pumpChat(tester, onlineChat);

    expect(find.widgetWithText(AppBar, onlineChat.name), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Online'), findsOneWidget);
  });

  testWidgets('shows offline status for offline contacts', (tester) async {
    await pumpChat(tester, offlineChat);

    expect(find.widgetWithText(AppBar, 'Offline'), findsOneWidget);
  });

  testWidgets('shows the last message in the conversation', (tester) async {
    await pumpChat(tester, onlineChat);

    expect(find.text(onlineChat.lastMessage), findsOneWidget);
  });

  testWidgets('send button adds the message and clears the input', (
    tester,
  ) async {
    await pumpChat(tester, onlineChat);

    await tester.enterText(find.byType(TextField), 'Hello from the test');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(find.text('Hello from the test'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('pressing enter on the keyboard sends the message', (
    tester,
  ) async {
    await pumpChat(tester, onlineChat);

    await tester.enterText(find.byType(TextField), 'Sent with enter');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(find.text('Sent with enter'), findsOneWidget);
  });

  testWidgets('blank messages are not sent', (tester) async {
    await pumpChat(tester, onlineChat);
    final bubbleCount = messageBubbles().evaluate().length;

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(messageBubbles().evaluate().length, bubbleCount);
  });

  testWidgets('sent messages are trimmed', (tester) async {
    await pumpChat(tester, onlineChat);

    await tester.enterText(find.byType(TextField), '  padded  ');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(find.text('padded'), findsOneWidget);
  });
}
