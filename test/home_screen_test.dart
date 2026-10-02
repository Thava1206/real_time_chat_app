import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:real_time_chat_app/screens/chat_screen.dart';
import 'package:real_time_chat_app/services/chat_service.dart';
import 'package:real_time_chat_app/screens/home_screen.dart';
import 'package:real_time_chat_app/services/user_service.dart';

// The Profile tab reads the signed-in Firebase user, which isn't available in
// widget tests, so it is covered separately in profile_tab_test.dart.

void main() {
  late ChatService chatService;

  Future<UserService> pumpHome(WidgetTester tester) async {
    final firestore = FakeFirebaseFirestore();
    final userService = UserService(firestore: firestore);
    chatService = ChatService(firestore: firestore, userService: userService);
    await userService.createProfile(
      uid: 'me',
      name: 'Current User',
      email: 'me@example.com',
    );
    await userService.createProfile(
      uid: 'maya',
      name: 'Maya Chen',
      email: 'maya@example.com',
    );
    await userService.createProfile(
      uid: 'priya',
      name: 'Priya Patel',
      email: 'priya@example.com',
    );
    await userService.addContact('me', 'maya');
    await chatService.sendMessage(
      senderId: 'priya',
      recipientId: 'me',
      text: 'Meeting moved to 3pm',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          currentUserId: 'me',
          userService: userService,
          chatService: chatService,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return userService;
  }

  testWidgets('opens on the Messages tab with the chat list', (tester) async {
    await pumpHome(tester);

    expect(find.widgetWithText(AppBar, 'Messages'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Search messages'), findsOneWidget);
    expect(find.text('Priya Patel'), findsOneWidget);
    expect(find.text('Meeting moved to 3pm'), findsOneWidget);
  });

  testWidgets('prefixes the preview when the user sent the last message', (
    tester,
  ) async {
    await pumpHome(tester);

    await chatService.sendMessage(
      senderId: 'me',
      recipientId: 'priya',
      text: 'See you then',
    );
    await tester.pumpAndSettle();

    expect(find.text('You: See you then'), findsOneWidget);
  });

  testWidgets('search filters the chat list', (tester) async {
    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Priya Patel'), findsNothing);

    await tester.enterText(find.byType(TextField), 'meeting');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Priya Patel'), findsOneWidget);
    expect(find.text('Received'), findsWidgets);
  });

  testWidgets('bottom bar switches to the Contacts tab', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Contacts'), findsOneWidget);
    expect(find.text('Search messages'), findsNothing);
    expect(find.byTooltip('Message'), findsOneWidget);
    expect(find.text('Maya Chen'), findsOneWidget);
    expect(find.text('Add Contact'), findsOneWidget);
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
    await tester.tap(find.text('Priya Patel'));
    await tester.pumpAndSettle();

    final screen = tester.widget<ChatScreen>(find.byType(ChatScreen));
    expect(screen.otherUser.uid, 'priya');
    expect(find.text('Meeting moved to 3pm'), findsOneWidget);
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
    expect(screen.otherUser.name, 'Maya Chen');
    expect(screen.currentUid, 'me');
  });

  testWidgets('Add Contact searches and saves a user under contacts', (
    tester,
  ) async {
    final userService = await pumpHome(tester);
    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Contact'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'priya@example.com');
    await tester.pump();
    await tester.tap(find.byTooltip('Search users'));
    await tester.pumpAndSettle();

    final dialog = find.byType(Dialog);
    expect(
      find.descendant(of: dialog, matching: find.text('Priya Patel')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: dialog, matching: find.byTooltip('Add Priya Patel')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Priya Patel'), findsOneWidget);
    final contacts = await userService.watchContacts('me').first;
    expect(contacts.map((contact) => contact.name), contains('Priya Patel'));
  });

  testWidgets('Contacts tab suggests people who are not contacts yet', (
    tester,
  ) async {
    final userService = await pumpHome(tester);
    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    // Priya messaged me but isn't a contact; Maya already is.
    expect(find.text('Suggested for you'), findsOneWidget);
    expect(find.text('Messaged you'), findsOneWidget);
    expect(find.byTooltip('Hide Maya Chen'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Add Priya Patel'));
    await tester.pumpAndSettle();

    final contacts = await userService.watchContacts('me').first;
    expect(contacts.map((contact) => contact.name), contains('Priya Patel'));
    expect(find.text('Suggested for you'), findsNothing);
    expect(find.text('Priya Patel'), findsOneWidget);
  });

  testWidgets('a suggestion can be hidden or opened as a chat', (tester) async {
    await pumpHome(tester);
    await tester.tap(find.text('Contacts'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Messaged you'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ChatScreen>(find.byType(ChatScreen)).otherUser.uid,
      'priya',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hide Priya Patel'));
    await tester.pumpAndSettle();
    expect(find.text('Suggested for you'), findsNothing);
  });
}
