import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Creates the cat document and flips `onboardingComplete` to `true` in a
  /// single atomic batch, so a partial save can never leave the user stranded
  /// between onboarding and home.
  Future<void> completeOnboarding(CatProfile profile) async {
    try {
      final DocumentReference<Map<String, dynamic>> userRef = _firestore
          .collection('users')
          .doc(_userId);
      final DocumentReference<Map<String, dynamic>> catRef = userRef
          .collection('cats')
          .doc();

      final Map<String, dynamic> data = profile.toJson()..remove('createdAt');
      data['id'] = catRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();

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
}
