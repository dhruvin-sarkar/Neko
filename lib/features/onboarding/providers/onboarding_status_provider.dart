import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../data/onboarding_persistence.dart';

part 'onboarding_status_provider.g.dart';

/// Streams whether the signed-in user has finished onboarding.
///
/// Emits `false` while signed out. A locally-persisted flag (set the first
/// time onboarding completes) is consulted first, so a returning user is taken
/// straight into the app instantly and offline. Otherwise it reads
/// `users/{uid}.onboardingComplete` reactively, and caches a `true` result
/// locally so subsequent launches short-circuit.
@Riverpod(keepAlive: true)
Stream<bool> onboardingComplete(Ref ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream<bool>.value(false);
  }

  final OnboardingPersistence persistence = ref.watch(
    onboardingPersistenceProvider,
  );

  // Fast path: a prior completion is cached on-device — no network needed.
  if (persistence.isComplete(user.uid)) {
    return Stream<bool>.value(true);
  }

  return ref
      .watch(firestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots()
      .map((doc) => (doc.data()?['onboardingComplete'] as bool?) ?? false)
      .map((complete) {
        // Persist a positive result so future launches skip the round-trip.
        if (complete) {
          unawaited(persistence.setComplete(user.uid));
        }
        return complete;
      });
}
