import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../chat/providers/chat_history_provider.dart';
import '../../onboarding/data/onboarding_persistence.dart';
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

@Riverpod(keepAlive: true)
Stream<GoogleSignInAccount?> googleAccountChanges(Ref ref) =>
    ref.watch(authRepositoryProvider).googleAccountChanges;

@riverpod
class AuthController extends _$AuthController {
  bool _disposed = false;

  @override
  FutureOr<void> build() {
    ref.onDispose(() => _disposed = true);
  }

  /// Sets [state] only if this controller hasn't been disposed. Sign-in success
  /// navigates away from the auth screens, which can dispose this (auto-dispose)
  /// controller before an in-flight call finishes — setting state then throws
  /// "Future already completed", so we guard against it.
  void _safeState(AsyncValue<void> value) {
    if (!_disposed) state = value;
  }

  Future<void> signIn({required String email, required String password}) async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    _safeState(
      await AsyncValue.guard(
        () => ref
            .read(authRepositoryProvider)
            .signInWithEmail(email: email, password: password),
      ),
    );
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    _safeState(
      await AsyncValue.guard(
        () => ref
            .read(authRepositoryProvider)
            .registerWithEmail(email: email, password: password),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    _safeState(
      await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).signInWithGoogle(),
      ),
    );
  }

  Future<void> signOut() async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    // Snapshot everything before the awaits — this auto-dispose controller can
    // be torn down mid-flight once sign-out starts navigating.
    final AuthRepository repository = ref.read(authRepositoryProvider);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    final String? uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    _safeState(
      await AsyncValue.guard(() async {
        await repository.signOut();
        // On-device transcripts must not outlive the account session.
        await clearChatHistoryFor(prefs, uid);
      }),
    );
  }

  Future<void> resetPassword(String email) async {
    if (state.isLoading) return;
    state = const AsyncValue<void>.loading();
    _safeState(
      await AsyncValue.guard(
        () => ref.read(authRepositoryProvider).sendPasswordReset(email),
      ),
    );
  }
}
