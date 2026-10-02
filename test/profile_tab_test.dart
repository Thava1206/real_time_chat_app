import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:real_time_chat_app/screens/profile_tab.dart';
import 'package:real_time_chat_app/theme/appearance_controller.dart';

void main() {
  Future<void> pumpProfile(
    WidgetTester tester, {
    VoidCallback? onLogOut,
    Future<void> Function(String name, String bio)? onSaveProfile,
    Future<void> Function(String? photo)? onChangePhoto,
    String bio = '',
    String? photo,
    AppearanceController? appearanceController,
  }) => tester.pumpWidget(
    AppearanceScope(
      controller: appearanceController ?? AppearanceController(),
      child: MaterialApp(
        home: Scaffold(
          body: ProfileTab(
            name: 'Jane Doe',
            email: 'jane@example.com',
            bio: bio,
            photo: photo,
            onLogOut: onLogOut ?? () {},
            onSaveProfile: onSaveProfile,
            onChangePhoto: onChangePhoto,
          ),
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
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('changes the appearance mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppearanceController();
    await pumpProfile(tester, appearanceController: controller);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Liquid glass'));
    await tester.pumpAndSettle();

    expect(controller.appearance, AppAppearance.liquidGlass);
    expect(find.text('Liquid glass'), findsOneWidget);
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

  testWidgets('removes the signed-in user profile photo', (tester) async {
    String? savedPhoto = 'not-called';
    final photo = base64Encode(img.encodePng(img.Image(width: 4, height: 4)));
    await pumpProfile(
      tester,
      photo: photo,
      onChangePhoto: (value) async => savedPhoto = value,
    );

    await tester.tap(find.byTooltip('Change profile photo'));
    await tester.pumpAndSettle();
    expect(find.text('Remove photo'), findsOneWidget);

    await tester.tap(find.text('Remove photo'));
    await tester.pumpAndSettle();

    expect(savedPhoto, isNull);
  });
}
