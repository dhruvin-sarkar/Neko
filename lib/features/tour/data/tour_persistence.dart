import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../onboarding/data/onboarding_persistence.dart';

/// Persists the "has seen the home guided tour" flag locally, per user, so the
/// premium first-run tour is shown exactly once and never nags a returning
/// user. Mirrors [OnboardingPersistence] so both first-run signals share the
/// same synchronous, offline-friendly storage.
class TourPersistence {
  TourPersistence(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String uid) => 'home_tour_seen_$uid';

  /// Whether [uid] has already been shown the home tour.
  bool hasSeen(String uid) => _prefs.getBool(_key(uid)) ?? false;

  /// Records that [uid] has now seen the home tour.
  Future<void> markSeen(String uid) => _prefs.setBool(_key(uid), true);
}

/// Exposes [TourPersistence] backed by the resolved preferences.
final tourPersistenceProvider = Provider<TourPersistence>(
  (ref) => TourPersistence(ref.watch(sharedPreferencesProvider)),
);
