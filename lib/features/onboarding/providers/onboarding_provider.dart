import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/validators.dart';
import '../data/calorie_calculator.dart';
import '../data/onboarding_persistence.dart';
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
  // Tracks disposal so async [save] never writes state after the notifier is
  // gone (Riverpod 2.x has no `ref.mounted`).
  bool _disposed = false;
  String? _uid;

  @override
  OnboardingState build() {
    ref.onDispose(() => _disposed = true);
    _uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    final String? uid = _uid;
    if (uid != null) {
      final saved = ref.read(onboardingPersistenceProvider).loadDraft(uid);
      if (saved != null) {
        // Drop a restored photo path whose temp file the OS has since cleared,
        // so the photo step and the final upload don't choke on a dead path.
        final String? photo = saved.draft.photoPath;
        final draft = (photo != null && !File(photo).existsSync())
            ? saved.draft.copyWith(photoPath: null)
            : saved.draft;
        return OnboardingState(step: saved.step, draft: draft);
      }
    }
    return const OnboardingState(step: 1);
  }

  /// Persists the current draft + step so the flow can resume after a cold
  /// start. Called when the step changes (captures every completed step).
  void _persist() {
    final String? uid = _uid;
    if (uid == null || _disposed) return;
    unawaited(
      ref
          .read(onboardingPersistenceProvider)
          .saveDraft(uid, state.draft, state.step),
    );
  }

  void setName(String name) {
    state = state.copyWith(draft: state.draft.copyWith(name: name));
    _persist();
  }

  void setBreed(String breed) {
    state = state.copyWith(draft: state.draft.copyWith(breed: breed));
    _persist();
  }

  void setAge({required int years, required int months}) {
    state = state.copyWith(
      draft: state.draft.copyWith(ageYears: years, ageMonths: months),
    );
    _persist();
  }

  void setBirthday(DateTime? birthday) {
    state = state.copyWith(draft: state.draft.copyWith(birthday: birthday));
    _persist();
  }

  void setWeight(double? weightKg) {
    state = state.copyWith(draft: state.draft.copyWith(weightKg: weightKg));
    _persist();
  }

  void setColorType(String colorType) {
    state = state.copyWith(draft: state.draft.copyWith(colorType: colorType));
    _persist();
  }

  void setActivityLevel(String activityLevel) {
    state = state.copyWith(
      draft: state.draft.copyWith(activityLevel: activityLevel),
    );
    _persist();
  }

  /// Sets (or clears, with `null`) the local path of the chosen cat photo.
  /// Choosing a photo clears any selected preset avatar.
  void setPhotoPath(String? photoPath) {
    state = state.copyWith(
      draft: state.draft.copyWith(photoPath: photoPath, avatarPreset: null),
    );
    _persist();
  }

  /// Selects (or clears) a bundled preset avatar. Choosing one clears any
  /// picked photo.
  void setAvatarPreset(String? avatarPreset) {
    state = state.copyWith(
      draft: state.draft.copyWith(avatarPreset: avatarPreset, photoPath: null),
    );
    _persist();
  }

  void nextStep() {
    if (state.step < _lastStep) {
      state = state.copyWith(step: state.step + 1);
      _persist();
    }
  }

  void previousStep() {
    if (state.step > 1) {
      state = state.copyWith(step: state.step - 1);
      _persist();
    }
  }

  /// Resets the flow to a clean draft — used when adding another cat.
  void reset() {
    final String? uid = _uid;
    if (uid != null) {
      unawaited(ref.read(onboardingPersistenceProvider).clearDraft(uid));
    }
    state = const OnboardingState(step: 1);
  }

  /// Persists the collected cat and marks onboarding complete.
  ///
  /// Returns `true` on success. On failure, surfaces a message via
  /// [OnboardingState.errorMessage] and returns `false`.
  Future<bool> save() async {
    // Guard against double-taps firing two saves.
    if (state.isSaving) return false;
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
      avatarPreset: draft.avatarPreset,
      dailyCalorieTarget: CalorieCalculator.dailyTarget(
        weightKg: draft.weightKg ?? 0,
        activity: draft.activityLevel ?? 'active',
      ),
    );

    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await ref
          .read(onboardingRepositoryProvider)
          .completeOnboarding(profile, photoPath: draft.photoPath);
      if (_disposed) return true;
      // Persist completion locally so a returning user skips onboarding even
      // before Firestore echoes the flag back (and while offline).
      final String? uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
      if (uid != null) {
        final persistence = ref.read(onboardingPersistenceProvider);
        await persistence.setComplete(uid);
        await persistence.clearDraft(uid);
      }
      if (_disposed) return true;
      state = state.copyWith(isSaving: false);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.message);
      return false;
    }
  }
}

/// Works out the progress bar and continue-button state for the current step.
StepConfig stepConfigOf(OnboardingState state) {
  final draft = state.draft;
  final bool canContinue = switch (state.step) {
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
