import 'package:firebase_auth/firebase_auth.dart';

import 'user_service.dart';

/// Thin wrapper around [FirebaseAuth] that translates errors into
/// user-friendly messages and exposes the auth state stream for session
/// persistence (Firebase automatically restores the session on app restart).
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, UserService? userService})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _userServiceOverride = userService;

  final FirebaseAuth _firebaseAuth;
  final UserService? _userServiceOverride;

  // Created lazily so screens that never sign in don't touch Firestore.
  late final UserService _userService = _userServiceOverride ?? UserService();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name.trim());
      await _userService.createProfile(uid: user.uid, name: name, email: email);
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageForException(e));
    } on FirebaseException {
      // The account exists but the profile write failed; signIn will retry it.
      throw AuthException(
        'Account created, but your profile could not be saved.',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user!;
      await _userService.ensureProfile(
        uid: user.uid,
        name: (user.displayName?.isNotEmpty ?? false)
            ? user.displayName!
            : 'User',
        email: user.email ?? email,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageForException(e));
    } on FirebaseException {
      throw AuthException('Signed in, but your profile could not be loaded.');
    }
  }

  Future<void> signOut() => _firebaseAuth.signOut();

  /// Updates the profile in Firestore and keeps the Firebase Auth display
  /// name in sync with it.
  Future<void> updateProfile({
    required String name,
    required String bio,
  }) async {
    final user = _firebaseAuth.currentUser!;
    try {
      await _userService.updateProfile(user.uid, name: name, bio: bio);
      await user.updateDisplayName(name.trim());
    } on FirebaseException {
      throw AuthException('Could not save your profile. Please try again.');
    }
  }

  String _messageForException(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'keychain-error':
        return 'Secure sign-in storage is unavailable. Check the macOS app signing and Keychain Sharing setup.';
      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled for this app.';
      case 'configuration-not-found':
        return 'Firebase Authentication is not configured for this app.';
      default:
        return exception.message ?? 'Something went wrong. Please try again.';
    }
  }
}

/// Error type surfaced to the UI so screens don't need to know about Firebase.
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
