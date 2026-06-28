import 'package:freezed_annotation/freezed_annotation.dart';

import 'onboarding_draft.dart';

part 'onboarding_state.freezed.dart';

/// Immutable state for the onboarding flow: the current [step], the
/// accumulated [draft], and transient save status.
@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(1) int step,
    @Default(OnboardingDraft()) OnboardingDraft draft,
    @Default(false) bool isSaving,
    String? errorMessage,
  }) = _OnboardingState;
}
