import 'dart:math' as math;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../data/onboarding_repository.dart';
import '../models/cat_profile.dart';
import '../models/onboarding_state.dart';
import '../models/step_config.dart';

part 'onboarding_provider.g.dart';

/// The last step index (0-based). Step 0 is the welcome screen; steps 1–7 are
/// the questions (name, photo, breed, age, weight, coat, activity).
const int _lastStep = 7;

/// Holds the in-progress cat draft and step position for the onboarding flow.
///
/// Nothing is persisted until [save]; that call writes the cat profile and the
/// `onboardingComplete` flag atomically, after which the router redirects.
@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  void setName(String name) =>
      state = state.copyWith(draft: state.draft.copyWith(name: name));

  void setBreed(String breed) =>
      state = state.copyWith(draft: state.draft.copyWith(breed: breed));

  void setAge({required int years, required int months}) =>
      state = state.copyWith(
        draft: state.draft.copyWith(ageYears: years, ageMonths: months),
      );

  void setBirthday(DateTime? birthday) =>
      state = state.copyWith(draft: state.draft.copyWith(birthday: birthday));

  void setWeight(double? weightKg) =>
      state = state.copyWith(draft: state.draft.copyWith(weightKg: weightKg));

  void setColorType(String colorType) =>
      state = state.copyWith(draft: state.draft.copyWith(colorType: colorType));

  void setActivityLevel(String activityLevel) => state = state.copyWith(
    draft: state.draft.copyWith(activityLevel: activityLevel),
  );

  /// Sets (or clears, with `null`) the local path of the chosen cat photo.
  void setPhotoPath(String? photoPath) =>
      state = state.copyWith(draft: state.draft.copyWith(photoPath: photoPath));

  void nextStep() {
    if (state.step < _lastStep) state = state.copyWith(step: state.step + 1);
  }

  void previousStep() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1);
  }

  /// Resets the flow to a clean draft — used when adding another cat.
  void reset() => state = const OnboardingState();

  /// Persists the collected cat and marks onboarding complete.
  ///
  /// Returns `true` on success. On failure, surfaces a message via
  /// [OnboardingState.errorMessage] and returns `false`.
  Future<bool> save() async {
    final draft = state.draft;
    final profile = CatProfile(
      id: '',
      name: draft.name.trim(),
      breed: draft.breed ?? 'Other',
      ageMonths: draft.totalMonths,
      weightKg: draft.weightKg ?? 0,
      colorType: draft.colorType ?? 'other',
      activityLevel: draft.activityLevel ?? 'active',
      birthday: draft.birthday,
      dailyCalorieTarget: _calorieTarget(
        draft.weightKg ?? 0,
        draft.activityLevel ?? 'active',
      ),
    );

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .completeOnboarding(profile, photoPath: draft.photoPath);
      state = state.copyWith(isSaving: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    }
  }

  /// Resting Energy Requirement scaled by activity, rounded to whole kcal.
  int _calorieTarget(double weightKg, String activity) {
    if (weightKg <= 0) return 0;
    final double rer = 70 * math.pow(weightKg, 0.75).toDouble();
    final double factor = switch (activity) {
      'couch' => 1.0,
      'outdoor' => 1.4,
      _ => 1.2,
    };
    return (rer * factor).round();
  }
}

/// Derives the chrome configuration (progress + continue button) for the
/// current onboarding state. Pure, so it is trivially testable.
StepConfig stepConfigOf(OnboardingState state) {
  final draft = state.draft;
  final bool canContinue = switch (state.step) {
    0 => true,
    1 => Validators.catName(draft.name) == null,
    2 => true, // photo is optional
    3 => draft.breed != null,
    4 => draft.totalMonths > 0,
    5 => (draft.weightKg ?? 0) > 0 && (draft.weightKg ?? 0) <= 30,
    6 => draft.colorType != null,
    7 => draft.activityLevel != null,
    _ => false,
  };

  return StepConfig(
    continueLabel: state.step == _lastStep ? "Let's go" : 'Continue',
    canContinue: canContinue,
    showProgress: state.step >= 1 && state.step <= _lastStep,
    progressFraction: state.step / _lastStep,
    isFinal: state.step == _lastStep,
    showChrome: state.step != 0,
  );
}
