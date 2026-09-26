// Basic smoke test for the login screen's form validation.
//
// Note: MyApp itself is not tested here because it calls Firebase.initializeApp,
// which requires platform channels unavailable in the widget test environment.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/screens/login_screen.dart';

void main() {
  testWidgets('Login screen shows validation errors for empty fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pump();

    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter your password.'), findsOneWidget);
  });
}

