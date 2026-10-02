import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/models/app_user.dart';
import 'package:real_time_chat_app/models/user_contact.dart';
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

  test(
    'searchUsers finds an exact email and excludes the signed-in user',
    () async {
      await userService.createProfile(
        uid: 'u1',
        name: 'Current User',
        email: 'current@example.com',
      );
      await userService.createProfile(
        uid: 'u2',
        name: 'Priya Patel',
        email: 'priya@example.com',
      );

      final users = await userService.searchUsers(
        ' priya@example.com ',
        excludingUid: 'u1',
      );

      expect(users.map((user) => user.name), ['Priya Patel']);
    },
  );

  test(
    'addContact stores a UserContact link and resolves its profile',
    () async {
      await userService.createProfile(
        uid: 'u1',
        name: 'Jane Doe',
        email: 'jane@example.com',
      );
      await userService.createProfile(
        uid: 'u2',
        name: 'Sam Okafor',
        email: 'sam@example.com',
      );

      await userService.addContact('u1', 'u2');

      final linkDocument = await firestore
          .collection('users')
          .doc('u1')
          .collection('contacts')
          .doc('u2')
          .get();
      final link = UserContact.fromFirestore(linkDocument);
      expect(link.uid, 'u2');
      expect(link.createdAt, isNotNull);

      final contacts = await userService.watchContacts('u1').first;
      expect(contacts.map((contact) => contact.name), ['Sam Okafor']);
    },
  );

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

  test('updateContact changes only the owner contact information', () async {
    await userService.createProfile(
      uid: 'u2',
      name: 'Sam Okafor',
      email: 'sam@example.com',
    );
    await userService.addContact('u1', 'u2');

    await userService.updateContact(
      'u1',
      'u2',
      displayName: ' Samuel ',
      note: ' Work friend ',
    );

    final contact = (await userService.watchContacts('u1').first).single;
    expect(contact.name, 'Samuel');
    expect(contact.bio, 'Work friend');

    final publicProfile = await userService.watchUser('u2').first;
    expect(publicProfile!.name, 'Sam Okafor');
    expect(publicProfile.bio, isEmpty);
  });
}
