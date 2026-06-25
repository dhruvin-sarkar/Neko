import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/profiles/ui/widgets/neko_nav_pill.dart';
import '../shared/services/feedback_service.dart';
import 'theme/app_colors.dart';

/// Hosts the Home and Settings tabs behind a persistent bottom nav pill.
///
/// The pill stays fixed while the [navigationShell] swaps the active branch,
/// so switching tabs never animates the chrome.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: Center(
            child: NekoNavPill(
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
