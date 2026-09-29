import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

/// Reads and writes user profiles in the `users` Firestore collection.
class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
  }) {
    final user = AppUser(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      avatarColor: AppUser.avatarColorFor(uid),
    );
    return _users.doc(uid).set(user.toFirestore());
  }

  /// Creates the profile only if it doesn't exist yet, for accounts that
  /// were registered before profiles were stored in Firestore.
  Future<void> ensureProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      await createProfile(uid: uid, name: name, email: email);
    }
  }

  /// Emits the profile whenever it changes, or null if it doesn't exist.
  Stream<AppUser?> watchUser(String uid) => _users
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);

  Future<void> updateProfile(String uid, {String? name, String? bio}) {
    return _users.doc(uid).update({
      if (name != null) 'name': name.trim(),
      if (name != null) 'nameLower': name.trim().toLowerCase(),
      if (bio != null) 'bio': bio.trim(),
    });
  }
}
