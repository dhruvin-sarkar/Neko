import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/utils/logger.dart';
import '../../onboarding/models/cat_profile.dart';

part 'profile_repository.g.dart';

/// Repository for the current user's cats. Profile data lives in Firestore;
/// media (photos, documents) lives on-device via [LocalStorageService].
@riverpod
ProfileRepository profileRepository(Ref ref) => ProfileRepository(
  firestore: ref.watch(firestoreProvider),
  userId: ref.watch(currentUserProvider).uid,
);

class ProfileRepository {
  ProfileRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _catsRef = firestore.collection('users').doc(userId).collection('cats');

  final CollectionReference<Map<String, dynamic>> _catsRef;

  /// Streams the user's cats, oldest first.
  ///
  /// Sorted on the client rather than via `orderBy('createdAt')`: a just-saved
  /// cat has a still-null server timestamp locally, and an order-by would drop
  /// it from results until the server confirms — so it wouldn't show on Home
  /// right after onboarding. Sorting here keeps pending writes visible (last).
  Stream<List<CatProfile>> watchAll() => _catsRef.snapshots().map((snap) {
    final List<CatProfile> cats = snap.docs
        .map(CatProfile.fromFirestore)
        .toList();
    cats.sort((a, b) {
      final DateTime? ad = a.createdAt;
      final DateTime? bd = b.createdAt;
      if (ad == null && bd == null) return 0;
      if (ad == null) return 1; // a is a pending write — keep it last
      if (bd == null) return -1;
      return ad.compareTo(bd);
    });
    return cats;
  });

  /// Updates an existing cat's editable fields. `id` and `createdAt` are never
  /// overwritten.
  Future<void> update(CatProfile profile) async {
    try {
      final Map<String, dynamic> data = profile.toJson()
        ..remove('id')
        ..remove('createdAt');
      await _catsRef.doc(profile.id).update(data);
    } on Object catch (e, st) {
      AppLogger.error('Failed to update cat', e, st);
      throw const AppException("We couldn't save your changes. Try again.");
    }
  }

  /// Permanently removes a cat: its Firestore document and its on-device media
  /// (profile photo + documents). The local cleanup is best-effort.
  Future<void> delete(String catId) async {
    try {
      await _catsRef.doc(catId).delete();
      await LocalStorageService.clearCatData(catId);
    } on Object catch (e, st) {
      AppLogger.error('Failed to delete cat', e, st);
      throw const AppException(
        "We couldn't remove that cat. Please try again.",
      );
    }
  }
}
