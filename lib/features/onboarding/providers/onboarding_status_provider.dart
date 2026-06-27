import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../profiles/data/profile_repository.dart';
import '../data/onboarding_persistence.dart';

part 'onboarding_status_provider.g.dart';

/// Streams whether the signed-in user has finished onboarding.
///
/// Emits `false` while signed out. Resolution order:
///   1. A locally-persisted flag (set the first time onboarding completes), so
///      a returning user is taken straight into the app instantly and offline.
///   2. The user's cats: anyone who already has a cat has, by definition,
///      finished onboarding. The decision is driven by the cat stream, so it
///      emits **only after** the cat list has actually loaded — a returning
///      user is therefore never momentarily routed into the add-a-cat flow (and
///      then stranded there, since `/onboarding` is intentionally sticky).
///   3. For users with no cats, the per-user `users/{uid}.onboardingComplete`
///      flag is consulted.
///
/// A positive result from (2) or (3) is cached locally so future launches
/// short-circuit on (1).
@Riverpod(keepAlive: true)
Stream<bool> onboardingComplete(Ref ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream<bool>.value(false);
  }

  final OnboardingPersistence persistence = ref.watch(
    onboardingPersistenceProvider,
  );

  // (1) Fast path: a prior completion is cached on-device — instant, offline.
  if (persistence.isComplete(user.uid)) {
    return Stream<bool>.value(true);
  }

  final firestore = ref.watch(firestoreProvider);
  final ProfileRepository repo = ref.watch(profileRepositoryProvider);

  // Drive the decision off the cat stream. `asyncMap` emits nothing until the
  // first cats snapshot arrives, so the provider stays in its loading state
  // (router holds on splash) and never produces a premature `false`.
  return repo.watchAll().asyncMap((cats) async {
    // (2) Has at least one cat → onboarding is done. Cache and short-circuit.
    if (cats.isNotEmpty) {
      unawaited(persistence.setComplete(user.uid));
      return true;
    }

    // (3) No cats yet → fall back to the per-user flag.
    try {
      final doc = await firestore.collection('users').doc(user.uid).get();
      final bool complete = (doc.data()?['onboardingComplete'] as bool?) ?? false;
      if (complete) {
        unawaited(persistence.setComplete(user.uid));
      }
      return complete;
    } on Object {
      // No cats and the flag is unreadable → treat as not onboarded.
      return false;
    }
  });
}
