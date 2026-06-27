import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared [GlobalKey]s marking the widgets the home tour spotlights.
///
/// The targets live in different parts of the tree — the greeting and cat
/// list sit in `HomeScreen`, while the nav pill is owned by `MainShell` — so
/// the keys are held centrally and handed to each widget through
/// [tourKeysProvider]. The tour reads these same keys to anchor its spotlight.
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
}

/// App-wide [TourKeys]. Kept alive so the keys are stable across rebuilds.
final tourKeysProvider = Provider<TourKeys>((ref) => TourKeys());

/// The Home scroll view's controller, shared so the guided tour can scroll a
/// target (e.g. the add-cat button below a long cat list) into view before
/// spotlighting it. Kept alive and disposed with the provider container.
final homeScrollControllerProvider = Provider<ScrollController>((ref) {
  final ScrollController controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});
