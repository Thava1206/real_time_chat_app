import 'package:cloud_firestore/cloud_firestore.dart';

/// A contact link stored at `users/{ownerUid}/contacts/{uid}`.
class UserContact {
  const UserContact({
    required this.uid,
    this.displayName,
    this.note = '',
    this.createdAt,
  });

  final String uid;
  final String? displayName;
  final String note;
  final DateTime? createdAt;

  factory UserContact.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const {};
    return UserContact(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'createdAt': FieldValue.serverTimestamp(),
  };
}
