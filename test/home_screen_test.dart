import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:real_time_chat_app/screens/chat_screen.dart';
import 'package:real_time_chat_app/screens/home_screen.dart';
import 'package:real_time_chat_app/services/chat_service.dart';
import 'package:real_time_chat_app/services/user_service.dart';

// The Profile tab reads the signed-in Firebase user, which isn't available in
// widget tests, so it is covered separately in profile_tab_test.dart.

void main() {
  Future<UserService> pumpHome(
    WidgetTester tester, {
    bool withConversation = false,
  }) async {
    final firestore = FakeFirebaseFirestore();
    final userService = UserService(firestore: firestore);
    final chatService = ChatService(firestore: firestore);
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
    if (withConversation) {
      await chatService.sendMessage(
        senderId: 'priya',
        recipientId: 'me',
        text: 'Meeting moved to 3pm',
      );
    }
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

  testWidgets('opens on the Messages tab with an empty chat list', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.widgetWithText(AppBar, 'Messages'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Search messages'), findsOneWidget);
    expect(find.textContaining('No conversations yet'), findsOneWidget);
  });

  testWidgets('lists stored conversations', (tester) async {
    await pumpHome(tester, withConversation: true);

    expect(find.text('Priya Patel'), findsOneWidget);
    expect(find.text('Meeting moved to 3pm'), findsOneWidget);
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
    await pumpHome(tester, withConversation: true);

    await tester.tap(find.text('Priya Patel'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Type a message'), findsOneWidget);
    expect(find.text('Meeting moved to 3pm'), findsOneWidget);
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
    expect(screen.other.name, 'Maya Chen');
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

    expect(find.text('Priya Patel'), findsOneWidget);
    await tester.tap(find.byTooltip('Add Priya Patel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Priya Patel'), findsOneWidget);
    final contacts = await userService.watchContacts('me').first;
    expect(contacts.map((contact) => contact.name), contains('Priya Patel'));
  });
}
