import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';

part 'onboarding_status_provider.g.dart';

/// Streams whether the signed-in user has finished onboarding.
///
/// Emits `false` while signed out. Reads `users/{uid}.onboardingComplete`
/// reactively so the router redirects automatically the moment the flag flips
/// to `true` after the final onboarding step.
@Riverpod(keepAlive: true)
Stream<bool> onboardingComplete(Ref ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream<bool>.value(false);
  }
  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => (doc.data()?['onboardingComplete'] as bool?) ?? false);
}
