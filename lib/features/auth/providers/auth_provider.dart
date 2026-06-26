import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../data/auth_repository.dart';

part 'auth_provider.g.dart';

/// The Google sign-in client.
@Riverpod(keepAlive: true)
GoogleSignIn googleSignIn(Ref ref) =>
    GoogleSignIn(scopes: const ['email', 'profile']);

/// The app-wide [AuthRepository].
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
  auth: ref.watch(firebaseAuthProvider),
  firestore: ref.watch(firestoreProvider),
  googleSignIn: ref.watch(googleSignInProvider),
);

/// Interactive Google account changes, used by the official web sign-in button.
/// When the web button completes the picker, the account flows through here and
/// [AuthController] completes Firebase sign-in.
@Riverpod(keepAlive: true)
Stream<GoogleSignInAccount?> googleAccountChanges(Ref ref) =>
    ref.watch(authRepositoryProvider).googleAccountChanges;

/// Drives auth actions and exposes their progress as an [AsyncValue].
///
/// The UI calls these methods, watches this controller for loading/error
/// state, and never navigates directly — a successful auth change flows
/// through [authStateChangesProvider] and the router redirect handles routing.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({required String email, required String password}) async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password),
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .registerWithEmail(email: email, password: password),
    );
  }

  Future<void> signInWithGoogle() async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  Future<void> signOut() async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }

  Future<void> resetPassword(String email) async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).sendPasswordReset(email),
    );
  }
}
