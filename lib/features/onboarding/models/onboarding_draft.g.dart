// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OnboardingDraftImpl _$$OnboardingDraftImplFromJson(
  Map<String, dynamic> json,
) => _$OnboardingDraftImpl(
  name: json['name'] as String? ?? '',
  breed: json['breed'] as String?,
  ageYears: (json['ageYears'] as num?)?.toInt() ?? 0,
  ageMonths: (json['ageMonths'] as num?)?.toInt() ?? 0,
  weightKg: (json['weightKg'] as num?)?.toDouble(),
  birthday: json['birthday'] == null
      ? null
      : DateTime.parse(json['birthday'] as String),
  colorType: json['colorType'] as String?,
  activityLevel: json['activityLevel'] as String?,
  photoPath: json['photoPath'] as String?,
  avatarPreset: json['avatarPreset'] as String?,
);

Map<String, dynamic> _$$OnboardingDraftImplToJson(
  _$OnboardingDraftImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'breed': instance.breed,
  'ageYears': instance.ageYears,
  'ageMonths': instance.ageMonths,
  'weightKg': instance.weightKg,
  'birthday': instance.birthday?.toIso8601String(),
  'colorType': instance.colorType,
  'activityLevel': instance.activityLevel,
  'photoPath': instance.photoPath,
  'avatarPreset': instance.avatarPreset,
};
