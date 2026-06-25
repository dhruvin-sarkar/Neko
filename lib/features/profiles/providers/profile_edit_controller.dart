import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../onboarding/models/cat_profile.dart';
import '../data/profile_repository.dart';

part 'profile_edit_controller.g.dart';

/// Drives saving edits to a cat profile and exposes progress as [AsyncValue].
@riverpod
class ProfileEditController extends _$ProfileEditController {
  @override
  FutureOr<void> build() {}

  /// Saves [profile]; returns `true` on success.
  Future<bool> save(CatProfile profile) async {
    if (state.isLoading) return false;
    state = const AsyncValue<void>.loading();
    final AsyncValue<void> result = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).update(profile),
    );
    state = result;
    return !result.hasError;
  }

  /// Permanently removes the cat with [catId]; returns `true` on success.
  Future<bool> delete(String catId) async {
    if (state.isLoading) return false;
    state = const AsyncValue<void>.loading();
    final AsyncValue<void> result = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).delete(catId),
    );
    state = result;
    return !result.hasError;
  }
}
