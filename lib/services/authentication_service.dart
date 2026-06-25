import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/utils/logger.dart';

class AuthenticationService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // Google Sign-In
  static Future<User?> signInWithGoogle() async {
    try {
      // Sign out first to ensure clean state
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in.
        AppLogger.debug('Google Sign-In cancelled by user');
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get ID token from Google Sign-In');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      return userCredential.user;
    } catch (e) {
      AppLogger.error('Google Sign-In failed', e);
      return null;
    }
  }

  // Email and Password Sign-In
  static Future<User?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided.');
      } else {
        throw Exception('Authentication failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Authentication error: $e');
    }
  }

  // Email and Password Sign-Up
  static Future<User?> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists with this email.');
      } else {
        throw Exception('Sign-up failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('Sign-up error: $e');
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      AppLogger.error('Sign-out failed', e);
    }
  }

  //Get features for the current user
  static User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  static bool isUserAuthenticated() {
    return _firebaseAuth.currentUser != null;
  }

  static String? getUserEmail() {
    return _firebaseAuth.currentUser?.email;
  }

  static String? getUserDisplayName() {
    return _firebaseAuth.currentUser?.displayName;
  }

  static Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }
}
