import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Whether [uid] has completed onboarding according to the local cache.
  bool isComplete(String uid) => _prefs.getBool(_key(uid)) ?? false;

  /// Records that [uid] has completed onboarding.
  Future<void> setComplete(String uid) => _prefs.setBool(_key(uid), true);
}

/// Exposes [OnboardingPersistence] backed by the resolved preferences.
final onboardingPersistenceProvider = Provider<OnboardingPersistence>(
  (ref) => OnboardingPersistence(ref.watch(sharedPreferencesProvider)),
);
