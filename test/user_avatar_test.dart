import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/models/app_user.dart';
import 'package:real_time_chat_app/theme/app_theme.dart';
import 'package:real_time_chat_app/widgets/user_avatar.dart';

void main() {
  Finder onlineDot() => find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).color == AppColors.online,
  );

  Future<void> pumpAvatar(WidgetTester tester, {required bool isOnline}) =>
      tester.pumpWidget(
        MaterialApp(
          home: UserAvatar(
            initials: 'MC',
            color: AppColors.plum,
            isOnline: isOnline,
          ),
        ),
      );

  testWidgets('shows initials', (tester) async {
    await pumpAvatar(tester, isOnline: false);

    expect(find.text('MC'), findsOneWidget);
  });

  testWidgets('shows the online dot only when online', (tester) async {
    await pumpAvatar(tester, isOnline: true);
    expect(onlineDot(), findsOneWidget);

    await pumpAvatar(tester, isOnline: false);
    expect(onlineDot(), findsNothing);
  });

  test('AppUser builds initials from the first two words', () {
    const user = AppUser(
      uid: 'u1',
      name: 'Maya Chen',
      email: '',
      avatarColor: AppColors.plum,
    );
    const longName = AppUser(
      uid: 'u2',
      name: 'Maya Lin Chen',
      email: '',
      avatarColor: AppColors.plum,
    );

    expect(user.initials, 'MC');
    expect(longName.initials, 'ML');
  });
}
