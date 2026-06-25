import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/timestamp_converter.dart';

part 'cat_profile.freezed.dart';
part 'cat_profile.g.dart';

/// An immutable cat profile, mirroring `users/{uid}/cats/{catId}` in Firestore.
@freezed
class CatProfile with _$CatProfile {
  const CatProfile._();

  const factory CatProfile({
    required String id,
    required String name,
    required String breed,
    required int ageMonths,
    required double weightKg,
    required String colorType,
    required String activityLevel,
    @TimestampConverter() DateTime? birthday,
    String? photoUrl,
    @Default(0) int dailyCalorieTarget,
    @TimestampConverter() DateTime? createdAt,
  }) = _CatProfile;

  factory CatProfile.fromJson(Map<String, dynamic> json) =>
      _$CatProfileFromJson(json);

  /// Builds a profile from a Firestore document, injecting the document id.
  factory CatProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return CatProfile.fromJson(<String, dynamic>{...data, 'id': doc.id});
  }

  /// Whole years and leftover months, for friendly display.
  int get years => ageMonths ~/ 12;
  int get months => ageMonths % 12;

  /// Renders the profile as context for the AI assistant's prompts.
  String toAIContext() {
    final String age = years > 0
        ? '$years year${years == 1 ? '' : 's'}${months > 0 ? ', $months month${months == 1 ? '' : 's'}' : ''}'
        : '$months month${months == 1 ? '' : 's'}';
    return 'Cat: $name\n'
        'Breed: $breed\n'
        'Age: $age\n'
        'Weight: ${weightKg}kg\n'
        'Activity: $activityLevel\n'
        'Daily calorie target: $dailyCalorieTarget kcal';
  }
}
