import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/user_recommendation.dart';
import 'user_service.dart';

/// Suggests people to chat with, so users don't have to know someone's exact
/// email to find them.
///
/// Scoring happens on the device from data the Firestore rules already let
/// the user read: their own profile, contacts and chats, plus the most
/// recently joined profiles. Other users' contact lists are private, so
/// "mutual friends" can't be used as a signal.
class RecommendationService {
  RecommendationService({
    FirebaseFirestore? firestore,
    UserService? userService,
    DateTime Function()? clock,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _userService = userService ?? UserService(firestore: firestore),
       _clock = clock ?? DateTime.now;

  /// How many of the newest profiles are considered as candidates.
  static const candidatePoolSize = 200;

  static const _chattedScore = 50;
  static const _sameDomainScore = 20;
  static const _sharedInterestScore = 8;
  static const _newUserScore = 3;
  static const _completeProfileScore = 1;
  static const _newUserWindow = Duration(days: 14);

  /// Domains shared by unrelated people, so matching them means nothing.
  static const _publicEmailDomains = {
    'gmail.com',
    'googlemail.com',
    'yahoo.com',
    'outlook.com',
    'hotmail.com',
    'live.com',
    'msn.com',
    'icloud.com',
    'me.com',
    'aol.com',
    'proton.me',
    'protonmail.com',
  };

  /// Common bio words that don't say anything about someone's interests.
  static const _stopWords = {
    'about',
    'also',
    'always',
    'and',
    'been',
    'being',
    'could',
    'every',
    'from',
    'have',
    'here',
    'just',
    'like',
    'love',
    'loves',
    'make',
    'more',
    'most',
    'much',
    'only',
    'really',
    'some',
    'than',
    'that',
    'their',
    'them',
    'then',
    'there',
    'they',
    'thing',
    'things',
    'this',
    'very',
    'what',
    'when',
    'where',
    'which',
    'will',
    'with',
    'would',
    'your',
  };

  final FirebaseFirestore _firestore;
  final UserService _userService;
  final DateTime Function() _clock;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Returns up to [limit] people [uid] isn't connected with yet, best first.
  Future<List<UserRecommendation>> recommendFor(
    String uid, {
    int limit = 10,
  }) async {
    final (me, contacts, chats, recent) = await (
      _users.doc(uid).get(),
      _users.doc(uid).collection('contacts').get(),
      _firestore
          .collection('chats')
          .where('participants', arrayContains: uid)
          .get(),
      _users
          .orderBy('createdAt', descending: true)
          .limit(candidatePoolSize)
          .get(),
    ).wait;

    final contactIds = {for (final doc in contacts.docs) doc.id};

    // The uid of everyone [uid] has chatted with, mapped to whether that
    // person sent the latest message.
    final chatPartners = <String, bool>{};
    for (final chat in chats.docs) {
      final data = chat.data();
      final other = (data['participants'] as List).cast<String>().firstWhere(
        (id) => id != uid,
        orElse: () => uid,
      );
      chatPartners[other] = data['lastSenderId'] == other;
    }

    final candidates = {
      for (final doc in recent.docs) doc.id: AppUser.fromFirestore(doc),
    };
    // Chat partners may have joined too long ago to be in the recent pool.
    final missingPartners = chatPartners.keys
        .where((id) => !candidates.containsKey(id) && !contactIds.contains(id))
        .toList();
    candidates.addAll(await _userService.fetchUsers(missingPartners));

    candidates
      ..remove(uid)
      ..removeWhere((id, _) => contactIds.contains(id));

    final myProfile = me.exists ? AppUser.fromFirestore(me) : null;
    final myDomain = _privateDomain(myProfile?.email);
    final myInterests = _interests(myProfile?.bio ?? '');
    final now = _clock();

    final recommendations = candidates.values.map((user) {
      var score = 0;
      final reasons = <String>[];

      final lastSentByThem = chatPartners[user.uid];
      if (lastSentByThem != null) {
        score += _chattedScore;
        reasons.add(lastSentByThem ? 'Messaged you' : 'You chatted before');
      }

      if (myDomain != null && _privateDomain(user.email) == myDomain) {
        score += _sameDomainScore;
        reasons.add('Also at $myDomain');
      }

      final shared = myInterests.intersection(_interests(user.bio)).toList()
        ..sort();
      if (shared.isNotEmpty) {
        score += _sharedInterestScore * shared.take(3).length;
        reasons.add('Also into ${shared.take(3).join(', ')}');
      }

      final joined = user.createdAt;
      if (joined != null && now.difference(joined) < _newUserWindow) {
        score += _newUserScore;
        reasons.add('New to the app');
      }

      if (user.photo != null) score += _completeProfileScore;
      if (user.bio.isNotEmpty) score += _completeProfileScore;

      if (reasons.isEmpty) reasons.add('Suggested for you');
      return UserRecommendation(user: user, score: score, reasons: reasons);
    }).toList();

    recommendations.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final aJoined = a.user.createdAt, bJoined = b.user.createdAt;
      if (aJoined != null && bJoined != null && aJoined != bJoined) {
        return bJoined.compareTo(aJoined);
      }
      return a.user.name.compareTo(b.user.name);
    });
    return recommendations.take(limit).toList();
  }

  /// The part of [email] after `@`, unless it's a public email provider.
  static String? _privateDomain(String? email) {
    final at = email?.lastIndexOf('@') ?? -1;
    if (at < 0) return null;
    final domain = email!.substring(at + 1).trim().toLowerCase();
    if (domain.isEmpty || _publicEmailDomains.contains(domain)) return null;
    return domain;
  }

  /// Meaningful words from a bio, used as a rough stand-in for interests.
  static Set<String> _interests(String bio) => bio
      .toLowerCase()
      .split(RegExp(r'[^a-z]+'))
      .where((word) => word.length >= 4 && !_stopWords.contains(word))
      .toSet();
}
