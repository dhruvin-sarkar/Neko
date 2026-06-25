import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/logger.dart';

/// Owns all authentication and the user-document side effects that go with it.
///
/// Every failure is translated into an [AppException] with a friendly message;
/// no [FirebaseAuthException] or other Firebase type ever escapes this class.
class AuthRepository {
  AuthRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  }) : _auth = auth,
       _firestore = firestore,
       _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Signs in with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e, st) {
      throw _mapAuthError(e, st);
    } on Object catch (e, st) {
      throw _mapUnknown(e, st);
    }
  }

  /// Creates an account, sets a display name, and writes the user document.
  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
      final User? user = credential.user;
      if (user == null) {
        throw const AppException(
          'Account creation did not complete. Try again.',
        );
      }
      final String displayName = _displayNameFromEmail(email);
      await user.updateDisplayName(displayName);
      await _ensureUserDocument(user, displayName: displayName);
    } on FirebaseAuthException catch (e, st) {
      throw _mapAuthError(e, st);
    } on Object catch (e, st) {
      throw _mapUnknown(e, st);
    }
  }

  /// Signs in with Google. Returns `false` if the user cancelled the picker,
  /// `true` on success. Throws [AppException] on failure.
  Future<bool> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return false;

      final GoogleSignInAuthentication auth = await account.authentication;
      if (auth.idToken == null) {
        throw const AppException(
          'Google did not return a valid token. Try again.',
        );
      }
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );
      final User? user = result.user;
      if (user != null) {
        await _ensureUserDocument(
          user,
          displayName:
              user.displayName ?? _displayNameFromEmail(user.email ?? ''),
        );
      }
      return true;
    } on FirebaseAuthException catch (e, st) {
      throw _mapAuthError(e, st);
    } on AppException {
      rethrow;
    } on Object catch (e, st) {
      throw _mapUnknown(e, st);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e, st) {
      throw _mapAuthError(e, st);
    } on Object catch (e, st) {
      throw _mapUnknown(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } on Object catch (e, st) {
      throw _mapUnknown(e, st);
    }
  }

  /// Creates or merges the `users/{uid}` document. `createdAt` is only written
  /// once (merge never overwrites an existing value because we use set-merge
  /// and the field is server-stamped on first write).
  Future<void> _ensureUserDocument(
    User user, {
    required String displayName,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _firestore
        .collection('users')
        .doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> existing = await ref.get();
    await ref.set({
      'displayName': displayName,
      'email': user.email ?? '',
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      if (!existing.exists) 'onboardingComplete': false,
    }, SetOptions(merge: true));
  }

  String _displayNameFromEmail(String email) {
    final String local = email.trim().split('@').first;
    if (local.isEmpty) return 'Friend';
    return local[0].toUpperCase() + local.substring(1);
  }

  AppException _mapAuthError(FirebaseAuthException e, StackTrace st) {
    AppLogger.warning('Auth error: ${e.code}', e, st);
    final String message = switch (e.code) {
      'invalid-email' => 'That email address doesn\'t look right.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'Email or password is incorrect.',
      'email-already-in-use' => 'An account already exists with that email.',
      'weak-password' =>
        'Please choose a stronger password (at least 8 characters).',
      'operation-not-allowed' =>
        'This sign-in method isn\'t enabled right now.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'No internet connection. Check your network and retry.',
      'account-exists-with-different-credential' =>
        'You already have an account using a different sign-in method.',
      'requires-recent-login' => 'Please sign in again to continue.',
      _ => 'Something went wrong while signing in. Please try again.',
    };
    return AppException(message, cause: e);
  }

  AppException _mapUnknown(Object e, StackTrace st) {
    AppLogger.error('Unexpected auth failure', e, st);
    return AppException('Something went wrong. Please try again.', cause: e);
  }
}
