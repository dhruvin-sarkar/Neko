import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_draft.freezed.dart';

/// The partially-built cat profile collected as the user moves through the
/// onboarding steps. Lives entirely in memory until the final save.
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

  /// Total age in months across the years and months fields.
  int get totalMonths => ageYears * 12 + ageMonths;
}
