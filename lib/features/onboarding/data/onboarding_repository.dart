import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/logger.dart';
import '../models/cat_profile.dart';

part 'onboarding_repository.g.dart';

/// Repository scoped to the current user for completing onboarding.
@riverpod
OnboardingRepository onboardingRepository(Ref ref) => OnboardingRepository(
  firestore: ref.watch(firestoreProvider),
  storage: ref.watch(firebaseStorageProvider),
  userId: ref.watch(currentUserProvider).uid,
);

class OnboardingRepository {
  OnboardingRepository({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required String userId,
  }) : _firestore = firestore,
       _storage = storage,
       _userId = userId;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String _userId;

  /// Creates the cat document and flips `onboardingComplete` to `true` in a
  /// single atomic batch, so a partial save can never leave the user stranded
  /// between onboarding and home.
  ///
  /// If [photoPath] is provided, the image is uploaded to Storage first and its
  /// download URL is stored on the cat. Photo upload is best-effort: a failed
  /// upload still saves the cat (without a photo) rather than blocking
  /// onboarding.
  Future<void> completeOnboarding(
    CatProfile profile, {
    String? photoPath,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> userRef = _firestore
          .collection('users')
          .doc(_userId);
      final DocumentReference<Map<String, dynamic>> catRef = userRef
          .collection('cats')
          .doc();

      final String? photoUrl = photoPath == null
          ? null
          : await _uploadAvatar(catId: catRef.id, path: photoPath);

      final Map<String, dynamic> data = profile.toJson()..remove('createdAt');
      data['id'] = catRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      if (photoUrl != null) data['photoUrl'] = photoUrl;

      final WriteBatch batch = _firestore.batch()
        ..set(catRef, data)
        ..set(userRef, <String, dynamic>{
          'onboardingComplete': true,
        }, SetOptions(merge: true));

      await batch.commit();
    } on Object catch (e, st) {
      AppLogger.error('Failed to complete onboarding', e, st);
      throw const AppException("We couldn't save your cat. Please try again.");
    }
  }

  /// Uploads the avatar and returns its download URL, or `null` on failure.
  Future<String?> _uploadAvatar({
    required String catId,
    required String path,
  }) async {
    try {
      final Reference ref = _storage.ref(
        'users/$_userId/cats/$catId/avatar.jpg',
      );
      await ref.putFile(
        File(path),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await ref.getDownloadURL();
    } on Object catch (e, st) {
      AppLogger.warning(
        'Avatar upload failed; saving cat without a photo',
        e,
        st,
      );
      return null;
    }
  }
}
