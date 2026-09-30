import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A user's public profile, stored at `users/{uid}` in Firestore.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.avatarColor,
    this.bio = '',
    this.createdAt,
  });

  /// Colors a new user's avatar can be assigned.
  static const avatarColors = [
    AppColors.plum,
    AppColors.forest,
    AppColors.terracotta,
    Color(0xFF3E6A8A),
    Color(0xFF8A6A3E),
  ];

  /// Picks a stable avatar color for [uid] so it doesn't change between
  /// devices or when the profile is recreated.
  static Color avatarColorFor(String uid) =>
      avatarColors[uid.codeUnits.fold(0, (a, b) => a + b) %
          avatarColors.length];

  final String uid;
  final String name;
  final String email;
  final Color avatarColor;
  final String bio;
  final DateTime? createdAt;

  String get initials => name
      .split(' ')
      .where((p) => p.isNotEmpty)
      .map((p) => p[0])
      .take(2)
      .join()
      .toUpperCase();

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? 'User',
      email: data['email'] as String? ?? '',
      avatarColor: data['avatarColor'] is int
          ? Color(data['avatarColor'] as int)
          : avatarColorFor(doc.id),
      bio: data['bio'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Fields written when the profile is first created. `nameLower` is kept as
  /// a normalized value for any future case-insensitive name search.
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'nameLower': name.toLowerCase(),
    'email': email,
    'avatarColor': avatarColor.toARGB32(),
    'bio': bio,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
