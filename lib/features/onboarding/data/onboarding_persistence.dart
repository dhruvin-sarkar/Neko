import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/logger.dart';
import '../models/onboarding_draft.dart';

/// The app-wide [SharedPreferences] instance.
///
/// Resolved once at startup and injected via an override in `main()`, so the
/// rest of the app can read it synchronously (no `await` on the hot path that
/// gates routing).
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main()',
  ),
);

/// Persists the "has finished onboarding" flag locally, per user, so a
/// returning user is taken straight into the app — instantly and offline —
/// without waiting on a Firestore round-trip.
class OnboardingPersistence {
  OnboardingPersistence(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String uid) => 'onboarding_complete_$uid';
  static String _draftKey(String uid) => 'onboarding_draft_$uid';

  /// Whether [uid] has completed onboarding according to the local cache.
  bool isComplete(String uid) => _prefs.getBool(_key(uid)) ?? false;

  /// Records that [uid] has completed onboarding.
  Future<void> setComplete(String uid) => _prefs.setBool(_key(uid), true);

  /// Saves the in-progress [draft] and [step] so onboarding resumes at the same
  /// place after a cold start (process death mid-onboarding).
  Future<void> saveDraft(String uid, OnboardingDraft draft, int step) {
    return _prefs.setString(
      _draftKey(uid),
      jsonEncode(<String, dynamic>{'step': step, 'draft': draft.toJson()}),
    );
  }

  /// Restores a saved draft + step, or null if none is stored or it can't be
  /// parsed (e.g. a stale schema).
  ({OnboardingDraft draft, int step})? loadDraft(String uid) {
    final String? raw = _prefs.getString(_draftKey(uid));
    if (raw == null) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        draft: OnboardingDraft.fromJson(map['draft'] as Map<String, dynamic>),
        step: (map['step'] as num).toInt(),
      );
    } on Object catch (e, st) {
      AppLogger.warning(
        'Failed to parse saved onboarding draft; discarding',
        e,
        st,
      );
      return null;
    }
  }

  /// Clears any saved draft (on completion or when starting a new cat).
  Future<void> clearDraft(String uid) => _prefs.remove(_draftKey(uid));
}

/// Exposes [OnboardingPersistence] backed by the resolved preferences.
final onboardingPersistenceProvider = Provider<OnboardingPersistence>(
  (ref) => OnboardingPersistence(ref.watch(sharedPreferencesProvider)),
);
