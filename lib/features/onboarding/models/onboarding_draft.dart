import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_draft.freezed.dart';
part 'onboarding_draft.g.dart';

/// The partially-built cat profile collected as the user moves through the
/// onboarding steps. Serialised to local storage so the flow can resume after a
/// cold start mid-onboarding.
@freezed
class OnboardingDraft with _$OnboardingDraft {
  const OnboardingDraft._();

  const factory OnboardingDraft({
    @Default('') String name,
    String? breed,
    @Default(0) int ageYears,
    @Default(0) int ageMonths,
    double? weightKg,
    DateTime? birthday,
    String? colorType,
    String? activityLevel,
    String? photoPath,
    String? avatarPreset,
  }) = _OnboardingDraft;

  factory OnboardingDraft.fromJson(Map<String, dynamic> json) =>
      _$OnboardingDraftFromJson(json);

  /// Total age in months across the years and months fields.
  int get totalMonths => ageYears * 12 + ageMonths;
}
