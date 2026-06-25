import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../onboarding/models/cat_profile.dart';
import '../data/profile_repository.dart';

part 'profile_provider.g.dart';

/// Streams the signed-in user's cat profiles. Emits an empty list while signed
/// out so the UI never reads from a repository without a user.
@riverpod
Stream<List<CatProfile>> catProfiles(Ref ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) {
    return Stream<List<CatProfile>>.value(const <CatProfile>[]);
  }
  return ref.watch(profileRepositoryProvider).watchAll();
}

/// Looks up a single cat by id from the streamed list. Returns `null` while the
/// list is still loading or if the cat no longer exists.
@riverpod
CatProfile? catById(Ref ref, String catId) {
  final List<CatProfile> cats =
      ref.watch(catProfilesProvider).valueOrNull ?? const <CatProfile>[];
  for (final CatProfile cat in cats) {
    if (cat.id == catId) return cat;
  }
  return null;
}
