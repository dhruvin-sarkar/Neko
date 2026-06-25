import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
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
}
