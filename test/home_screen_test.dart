import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/data/sample_data.dart';
import 'package:real_time_chat_app/screens/chat_screen.dart';
import 'package:real_time_chat_app/screens/home_screen.dart';

// The Profile tab reads the signed-in Firebase user, which isn't available in
// widget tests, so it is covered separately in profile_tab_test.dart.

void main() {
  Future<void> pumpHome(WidgetTester tester) =>
      tester.pumpWidget(const MaterialApp(home: HomeScreen()));

  testWidgets('opens on the Messages tab with the chat list', (tester) async {
    await pumpHome(tester);

    expect(find.widgetWithText(AppBar, 'Messages'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Search messages'), findsOneWidget);
    for (final chat in sampleChats) {
      expect(find.text(chat.name), findsOneWidget);
    }
  });

  testWidgets('shows unread counts on chats with unread messages', (
    tester,
  ) async {
    await pumpHome(tester);

    for (final chat in sampleChats.where((c) => c.unread > 0)) {
      expect(find.widgetWithText(Badge, '${chat.unread}'), findsOneWidget);
    }
  });

  testWidgets('bottom bar switches to the Contacts tab', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Contacts'), findsOneWidget);
    expect(find.text('Search messages'), findsNothing);
    expect(find.byTooltip('Message'), findsNWidgets(sampleChats.length));
    // The new-chat button only belongs on the Messages tab.
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('bottom bar switches back to Messages', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Messages').last);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Messages'), findsOneWidget);
    expect(find.text('Search messages'), findsOneWidget);
  });

  testWidgets('new chat button opens the Contacts tab', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('New chat'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Contacts'), findsOneWidget);
  });

  testWidgets('tapping a chat opens that conversation', (tester) async {
    await pumpHome(tester);
    final chat = sampleChats.first;

    await tester.tap(find.text(chat.name));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Type a message'), findsOneWidget);
  });

  testWidgets('message button on a contact opens that conversation', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Message').first);
    await tester.pumpAndSettle();

    final screen = tester.widget<ChatScreen>(find.byType(ChatScreen));
    expect(screen.chat.name, sampleChats.first.name);
  });
}
