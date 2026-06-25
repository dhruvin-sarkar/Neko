import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/logger.dart';
import '../../onboarding/models/cat_profile.dart';

part 'profile_repository.g.dart';

/// Repository for the current user's cats.
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
  Stream<List<CatProfile>> watchAll() => _catsRef
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(CatProfile.fromFirestore).toList());

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
}
