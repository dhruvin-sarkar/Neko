import 'dart:async';

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

  /// Interactive Google account stream. The official web sign-in button (the
  /// `google_sign_in_web` rendered button) drives this stream: when the user
  /// completes the Google picker, the resulting account flows through here.
  Stream<GoogleSignInAccount?> get googleAccountChanges =>
      _googleSignIn.onCurrentUserChanged;

  /// Signs in with email and password.
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final User? user = await _runAuth(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );
      // Signing in means the account already exists, so make sure they're
      // marked onboarded and land Home rather than back in the add-a-cat flow.
      if (user != null) {
        await _ensureUserDocument(
          user,
          displayName: user.displayName ?? _displayNameFromEmail(email),
        );
      }
    } on FirebaseAuthException catch (e, st) {
      throw _mapAuthError(e, st);
    } on AppException {
      rethrow;
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
      final User? user = await _runAuth(
        () => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );
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
    } on AppException {
      rethrow;
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
      final User? user = await _runAuth(
        () => _auth.signInWithCredential(credential),
      );
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

  /// Completes Firebase sign-in from an already-obtained Google [account].
  ///
  /// Used by the web sign-in flow, where the official `google_sign_in_web`
  /// button performs the interactive picker and surfaces the account through
  /// [googleAccountChanges]. Reuses the same token → credential →
  /// `signInWithCredential` → user-document logic as [signInWithGoogle].
  /// Returns `true` on success. Throws [AppException] on failure.
  Future<bool> completeGoogleSignIn(GoogleSignInAccount account) async {
    try {
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
      final User? user = await _runAuth(
        () => _auth.signInWithCredential(credential),
      );
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

  /// Runs a Firebase auth [action] and returns the signed-in [User].
  ///
  /// Works around a known firebase_auth (v4 line) bug where the native sign-in
  /// succeeds but decoding the returned credential throws a type-cast error
  /// (`type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?'`).
  /// When that happens we don't fail the sign-in: if a user is actually
  /// authenticated, we return it. Real auth failures still surface as
  /// [FirebaseAuthException] and propagate unchanged.
  Future<User?> _runAuth(Future<UserCredential> Function() action) async {
    try {
      final UserCredential credential = await action();
      return credential.user ?? _auth.currentUser;
    } on FirebaseAuthException {
      rethrow;
    } on Object catch (e, st) {
      final User? recovered = await _userAfterDecodeError();
      if (recovered == null) throw _mapUnknown(e, st);
      AppLogger.warning(
        'Recovered from firebase_auth credential decode bug',
        e,
        st,
      );
      return recovered;
    }
  }

  /// After a credential-decode error, resolve the actually-signed-in user —
  /// immediately if available, otherwise by briefly waiting for the auth state
  /// to settle.
  Future<User?> _userAfterDecodeError() async {
    if (_auth.currentUser != null) return _auth.currentUser;
    try {
      return await _auth
          .authStateChanges()
          .firstWhere((User? u) => u != null)
          .timeout(const Duration(seconds: 3));
    } on Object {
      return _auth.currentUser;
    }
  }

  /// Creates or merges the `users/{uid}` document. Best-effort: a failure here
  /// (e.g. Firestore rules or a transient network error) is logged but never
  /// thrown, so it can't turn an otherwise-successful sign-in into an error.
  ///
  /// The `onboardingComplete` and `guidedTourComplete` flags are owned by the
  /// onboarding and tour flows. On a brand-new account (no document yet) they
  /// start `false`. For a returning account we only refresh the contact fields
  /// and never touch those flags — otherwise a sign-in could overwrite a real
  /// `true` back to `false` and wrongly send the user through onboarding again.
  /// `createdAt` is only stamped on first write.
  Future<void> _ensureUserDocument(
    User user, {
    required String displayName,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref = _firestore
          .collection('users')
          .doc(user.uid);
      final DocumentSnapshot<Map<String, dynamic>> existing = await ref.get();
      if (existing.exists) {
        // Returning account — refresh contact details only.
        await ref.set({
          'displayName': displayName,
          'email': user.email ?? '',
        }, SetOptions(merge: true));
      } else {
        // First time we've seen this account — a new user hasn't onboarded yet.
        await ref.set(<String, dynamic>{
          'displayName': displayName,
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'onboardingComplete': false,
          'guidedTourComplete': false,
        });
      }
    } on Object catch (e, st) {
      AppLogger.warning('Could not sync user document; continuing', e, st);
    }
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
    AppLogger.error('Unexpected auth failure (${e.runtimeType}): $e', e, st);
    return AppException('Something went wrong. Please try again.', cause: e);
  }
}
