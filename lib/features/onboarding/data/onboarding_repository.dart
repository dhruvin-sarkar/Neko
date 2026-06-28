import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/utils/logger.dart';
import '../models/cat_profile.dart';

part 'onboarding_repository.g.dart';

/// Repository scoped to the current user for completing onboarding.
@riverpod
OnboardingRepository onboardingRepository(Ref ref) => OnboardingRepository(
  firestore: ref.watch(firestoreProvider),
  userId: ref.watch(currentUserProvider).uid,
);

class OnboardingRepository {
  OnboardingRepository({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  /// Creates the cat document and sets `onboardingComplete: true` in one atomic
  /// batch. If [photoPath] is given, the photo is saved on-device afterwards; a
  /// failed photo save still keeps the cat (just without a picture) rather than
  /// blocking onboarding.
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

      // Drop the client createdAt and every null optional field (birthday,
      // avatarPreset) so we never persist explicit nulls to Firestore.
      final Map<String, dynamic> data = profile.toJson()
        ..remove('createdAt')
        ..removeWhere((_, Object? v) => v == null);
      data['id'] = catRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();

      final WriteBatch batch = _firestore.batch()
        ..set(catRef, data)
        ..set(userRef, <String, dynamic>{
          'onboardingComplete': true,
        }, SetOptions(merge: true));
      await batch.commit();

      // Save the chosen photo on-device (best-effort; never blocks onboarding).
      if (photoPath != null) {
        try {
          final bytes = await XFile(photoPath).readAsBytes();
          await LocalStorageService.saveProfilePicture(catRef.id, bytes);
        } on Object catch (e, st) {
          AppLogger.warning('Could not save cat photo on device', e, st);
        }
      }
    } on Object catch (e, st) {
      AppLogger.error('Failed to complete onboarding', e, st);
      throw const AppException("We couldn't save your cat. Please try again.");
    }
  }
}
