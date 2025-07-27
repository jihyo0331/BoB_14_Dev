import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service for email/password login and registration.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns the currently signed-in user, or null if none.
  static User? get currentUser => _auth.currentUser;

  /// Signs in a user with email and password.
  /// Returns the [User] on success, or null on failure.
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  /// Registers a new user with email and password.
  /// Returns the [User] on success, or null on failure.
  static Future<User?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  /// Signs out the current user.
  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
