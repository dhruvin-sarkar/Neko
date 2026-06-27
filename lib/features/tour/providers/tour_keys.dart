import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TourKeys {
  /// The "Welcome back" greeting at the top of Home.
  final GlobalKey greeting = GlobalKey(debugLabel: 'tour_greeting');

  /// The user's first cat banner (only present once a cat exists).
  final GlobalKey firstCat = GlobalKey(debugLabel: 'tour_first_cat');

  /// The "+" button on the add-cat affordance.
  final GlobalKey addCatPlus = GlobalKey(debugLabel: 'tour_add_cat_plus');

  /// The Home destination in the bottom nav pill.
  final GlobalKey navHome = GlobalKey(debugLabel: 'tour_nav_home');

  /// The Settings destination in the bottom nav pill.
  final GlobalKey navSettings = GlobalKey(debugLabel: 'tour_nav_settings');

  // ── Cat profile detail screen ──

  /// The block of stat cards (age, weight, activity, calories).
  final GlobalKey profileStats = GlobalKey(debugLabel: 'tour_profile_stats');

  /// The edit action in the profile app bar.
  final GlobalKey profileEdit = GlobalKey(debugLabel: 'tour_profile_edit');

  /// The Documents section (upload vet records, passports, etc.).
  final GlobalKey profileDocuments = GlobalKey(
    debugLabel: 'tour_profile_documents',
  );
}

/// App-wide [TourKeys]. Kept alive so the keys are stable across rebuilds.
final tourKeysProvider = Provider<TourKeys>((ref) => TourKeys());

final homeScrollControllerProvider = Provider<ScrollController>((ref) {
  final ScrollController controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// The cat profile detail screen's scroll controller, shared so the guided tour
/// can scroll the Documents section into view before spotlighting it.
final profileScrollControllerProvider = Provider<ScrollController>((ref) {
  final ScrollController controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});
