import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  storage: ref.watch(firebaseStorageProvider),
  userId: ref.watch(currentUserProvider).uid,
);

class ProfileRepository {
  ProfileRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required String userId,
  }) : _firestore = firestore,
       _storage = storage,
       _userId = userId,
       _catsRef = firestore.collection('users').doc(userId).collection('cats');

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _userId;
  final CollectionReference<Map<String, dynamic>> _catsRef;

  /// Streams the user's cats, oldest first.
  ///
  /// I sort on the client rather than with `orderBy('createdAt')` in the query:
  /// a just-saved cat has a server timestamp that's still null locally, and a
  /// `createdAt` order-by would drop it from the results until the server
  /// confirms — so the new cat wouldn't show up on Home right after onboarding.
  /// Sorting here keeps pending writes visible (newest, at the end).
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

  /// Permanently removes a cat: its document metadata, the cat document itself,
  /// and (best-effort) its Storage files. The Firestore deletes are atomic; a
  /// leftover Storage object is non-fatal and only logged.
  Future<void> delete(String catId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> docs = await _catsRef
          .doc(catId)
          .collection('documents')
          .get();

      final WriteBatch batch = _firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_catsRef.doc(catId));
      await batch.commit();

      await _deleteStorageFolder(catId);
    } on Object catch (e, st) {
      AppLogger.error('Failed to delete cat', e, st);
      throw const AppException(
        "We couldn't remove that cat. Please try again.",
      );
    }
  }

  /// Best-effort removal of a cat's Storage files (avatar + documents). Failures
  /// here never surface to the user — the metadata is already gone.
  Future<void> _deleteStorageFolder(String catId) async {
    Future<void> deleteAllIn(Reference ref) async {
      final ListResult result = await ref.listAll();
      for (final Reference item in result.items) {
        await item.delete();
      }
    }

    try {
      final Reference base = _storage.ref('users/$_userId/cats/$catId');
      await deleteAllIn(base);
      await deleteAllIn(base.child('documents'));
    } on Object catch (e, st) {
      AppLogger.warning('Cat storage cleanup failed (non-fatal)', e, st);
    }
  }
}
