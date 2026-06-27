import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/profiles/ui/widgets/neko_nav_pill.dart';
import '../features/settings/providers/theme_controller.dart';
import '../features/tour/providers/tour_keys.dart';
import '../shared/motion/page_transitions.dart';
import '../shared/services/feedback_service.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourKeys = ref.read(tourKeysProvider);
    // Rebuild the shell (and its nav pill) when the colour theme changes.
    ref.watch(themeControllerProvider);
    return RecedeOnCover(
      child: Scaffold(
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
      ),
    );
  }
}
