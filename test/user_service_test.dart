import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/models/app_user.dart';
import 'package:real_time_chat_app/services/user_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserService userService;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    userService = UserService(firestore: firestore);
  });

  test('createProfile stores the user under users/{uid}', () async {
    await userService.createProfile(
      uid: 'u1',
      name: ' Jane Doe ',
      email: 'jane@example.com',
    );

    final doc = await firestore.collection('users').doc('u1').get();
    expect(doc.data()!['name'], 'Jane Doe');
    expect(doc.data()!['nameLower'], 'jane doe');
    expect(doc.data()!['email'], 'jane@example.com');
    expect(doc.data()!['bio'], '');
    expect(doc.data()!['avatarColor'], AppUser.avatarColorFor('u1').toARGB32());
  });

  test('ensureProfile does not overwrite an existing profile', () async {
    await userService.createProfile(
      uid: 'u1',
      name: 'Jane Doe',
      email: 'jane@example.com',
    );
    await userService.updateProfile('u1', bio: 'Hello');

    await userService.ensureProfile(
      uid: 'u1',
      name: 'Someone Else',
      email: 'jane@example.com',
    );

    final user = await userService.watchUser('u1').first;
    expect(user!.name, 'Jane Doe');
    expect(user.bio, 'Hello');
  });

  test('ensureProfile creates a missing profile', () async {
    await userService.ensureProfile(
      uid: 'u2',
      name: 'Sam Okafor',
      email: 'sam@example.com',
    );

    final user = await userService.watchUser('u2').first;
    expect(user!.name, 'Sam Okafor');
    expect(user.initials, 'SO');
  });

  test('watchUser emits null for a missing profile', () async {
    expect(await userService.watchUser('nobody').first, isNull);
  });

  test('updateProfile changes name, search name and bio', () async {
    await userService.createProfile(
      uid: 'u1',
      name: 'Jane Doe',
      email: 'jane@example.com',
    );

    await userService.updateProfile('u1', name: 'Jane Smith', bio: ' Hi! ');

    final doc = await firestore.collection('users').doc('u1').get();
    expect(doc.data()!['name'], 'Jane Smith');
    expect(doc.data()!['nameLower'], 'jane smith');
    expect(doc.data()!['bio'], 'Hi!');
  });
}
