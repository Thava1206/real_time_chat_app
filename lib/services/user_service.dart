import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/user_contact.dart';

/// Reads and writes user profiles in the `users` Firestore collection.
class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _contacts(String uid) =>
      _users.doc(uid).collection('contacts');

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

  Stream<List<AppUser>> watchContacts(String uid) =>
      _contacts(uid).snapshots().asyncMap((snapshot) async {
        final contacts = snapshot.docs.map(UserContact.fromFirestore).toList();
        final profilesById = await fetchUsers(
          contacts.map((contact) => contact.uid).toList(),
        );

        return contacts
            .map((contact) => profilesById[contact.uid])
            .whereType<AppUser>()
            .toList();
      });

  /// Loads the profiles for [uids], keyed by uid. Missing profiles are left
  /// out. Firestore allows at most 30 ids per `whereIn`, so this batches.
  Future<Map<String, AppUser>> fetchUsers(List<String> uids) async {
    final ids = uids.toSet().toList();
    final profilesById = <String, AppUser>{};

    for (var start = 0; start < ids.length; start += 30) {
      final batch = ids.skip(start).take(30).toList();
      final profiles = await _users
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      for (final profile in profiles.docs) {
        profilesById[profile.id] = AppUser.fromFirestore(profile);
      }
    }

    return profilesById;
  }

  Future<List<AppUser>> searchUsers(
    String query, {
    required String excludingUid,
  }) async {
    final email = query.trim();
    if (email.isEmpty) return [];

    final snapshot = await _users
        .where('email', isEqualTo: email)
        .limit(10)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != excludingUid)
        .map(AppUser.fromFirestore)
        .toList();
  }

  Future<void> addContact(String uid, String contactUid) {
    if (uid == contactUid) {
      throw ArgumentError.value(contactUid, 'contactUid', 'Cannot add self');
    }

    return _contacts(uid)
        .doc(contactUid)
        .set(UserContact(uid: contactUid).toFirestore());
  }

  Future<void> updateProfile(String uid, {String? name, String? bio}) {
    return _users.doc(uid).update({
      if (name != null) 'name': name.trim(),
      if (name != null) 'nameLower': name.trim().toLowerCase(),
      if (bio != null) 'bio': bio.trim(),
    });
  }

  /// Sets the base64-encoded profile [photo], or removes it when null.
  Future<void> updatePhoto(String uid, String? photo) {
    return _users.doc(uid).update({'photo': photo ?? FieldValue.delete()});
  }
}
