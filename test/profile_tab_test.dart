import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/screens/profile_tab.dart';

void main() {
  Future<void> pumpProfile(WidgetTester tester, {VoidCallback? onLogOut}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProfileTab(
              name: 'Jane Doe',
              email: 'jane@example.com',
              onLogOut: onLogOut ?? () {},
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
}
