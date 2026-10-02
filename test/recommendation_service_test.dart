import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:real_time_chat_app/services/chat_service.dart';
import 'package:real_time_chat_app/services/recommendation_service.dart';
import 'package:real_time_chat_app/services/user_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserService userService;

  RecommendationService service({DateTime? now}) => RecommendationService(
    firestore: firestore,
    userService: userService,
    clock: now == null ? null : () => now,
  );

  Future<void> addUser(String uid, String email, {String bio = ''}) async {
    await userService.createProfile(uid: uid, name: uid, email: email);
    if (bio.isNotEmpty) await userService.updateProfile(uid, bio: bio);
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    userService = UserService(firestore: firestore);
  });

  test('excludes the user and their existing contacts', () async {
    await addUser('me', 'me@gmail.com');
    await addUser('friend', 'friend@gmail.com');
    await addUser('stranger', 'stranger@gmail.com');
    await userService.addContact('me', 'friend');

    final results = await service().recommendFor('me');

    expect(results.map((r) => r.user.uid), ['stranger']);
  });

  test('ranks chat partners, then classmates, then shared interests', () async {
    await addUser('me', 'me@school.edu', bio: 'Hiking and chess');
    await addUser('chatter', 'chatter@gmail.com');
    await addUser('classmate', 'classmate@school.edu');
    await addUser('hiker', 'hiker@gmail.com', bio: 'Weekend hiking trips');
    await addUser('other', 'other@gmail.com');
    await ChatService(
      firestore: firestore,
      userService: userService,
    ).sendMessage(senderId: 'chatter', recipientId: 'me', text: 'Hi!');

    final results = await service(
      now: DateTime.now().add(const Duration(days: 30)),
    ).recommendFor('me');

    expect(results.map((r) => r.user.uid), [
      'chatter',
      'classmate',
      'hiker',
      'other',
    ]);
    expect(results[0].reasons.first, 'Messaged you');
    expect(results[1].reasons.first, 'Also at school.edu');
    expect(results[2].reasons.first, 'Also into hiking');
    expect(results[3].reasons.first, 'Suggested for you');
  });

  test('public email domains and filler words are not matches', () async {
    await addUser('me', 'me@gmail.com', bio: 'I really love this');
    await addUser('other', 'other@gmail.com', bio: 'Really love this too');

    final results = await service(
      now: DateTime.now().add(const Duration(days: 30)),
    ).recommendFor('me');

    expect(results.single.reasons, ['Suggested for you']);
  });

  test('flags people who joined recently', () async {
    await addUser('me', 'me@gmail.com');
    await addUser('newbie', 'newbie@gmail.com');

    final results = await service().recommendFor('me');

    expect(results.single.reasons, ['New to the app']);
  });

  test('respects the limit', () async {
    await addUser('me', 'me@gmail.com');
    for (var i = 0; i < 5; i++) {
      await addUser('user$i', 'user$i@gmail.com');
    }

    final results = await service().recommendFor('me', limit: 3);

    expect(results, hasLength(3));
  });
}
