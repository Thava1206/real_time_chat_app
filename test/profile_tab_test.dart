import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/screens/profile_tab.dart';

void main() {
  Future<void> pumpProfile(
    WidgetTester tester, {
    VoidCallback? onLogOut,
    Future<void> Function(String name, String bio)? onSaveProfile,
    String bio = '',
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProfileTab(
          name: 'Jane Doe',
          email: 'jane@example.com',
          bio: bio,
          onLogOut: onLogOut ?? () {},
          onSaveProfile: onSaveProfile,
        ),
      ),
    ),
  );

  testWidgets('shows the user name, email and initials', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Jane Doe'), findsOneWidget);
    expect(find.text('jane@example.com'), findsOneWidget);
    expect(find.text('JD'), findsOneWidget);
  });

  testWidgets('shows the settings options', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
  });

  testWidgets('tapping log out calls the log out callback', (tester) async {
    var loggedOut = false;
    await pumpProfile(tester, onLogOut: () => loggedOut = true);

    await tester.tap(find.text('Log out'));
    await tester.pump();

    expect(loggedOut, isTrue);
  });

  testWidgets('shows the bio when there is one', (tester) async {
    await pumpProfile(tester, bio: 'CS student');

    expect(find.text('CS student'), findsOneWidget);
  });

  testWidgets('edit profile saves the new name and bio', (tester) async {
    String? savedName;
    String? savedBio;
    await pumpProfile(
      tester,
      onSaveProfile: (name, bio) async {
        savedName = name;
        savedBio = bio;
      },
    );

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Name'),
      'Jane Smith',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Bio'), 'Hi');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(savedName, 'Jane Smith');
    expect(savedBio, 'Hi');
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('edit profile requires a name', (tester) async {
    var saved = false;
    await pumpProfile(tester, onSaveProfile: (_, _) async => saved = true);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), ' ');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Please enter your name.'), findsOneWidget);
    expect(saved, isFalse);
  });
}
