import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/profiles/ui/widgets/neko_nav_pill.dart';
import '../features/tour/providers/tour_keys.dart';
import '../shared/motion/page_transitions.dart';
import '../shared/services/feedback_service.dart';

/// Hosts the Home and Settings tabs behind a persistent bottom nav pill.
///
/// The pill stays fixed while the [navigationShell] swaps the active branch.
/// Switching tabs plays a quick blur-in + fade on the branch content via
/// [BlurBranchSwitcher], so tabs come into focus rather than snapping.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourKeys = ref.read(tourKeysProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlurBranchSwitcher(
        index: navigationShell.currentIndex,
        child: navigationShell,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: NekoNavPill(
              homeKey: tourKeys.navHome,
              settingsKey: tourKeys.navSettings,
              selectedIndex: navigationShell.currentIndex,
              onSelect: (index) {
                unawaited(ref.read(feedbackServiceProvider).onTap());
                navigationShell.goBranch(
                  index,
                  // Re-tapping the active tab returns it to its root.
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
