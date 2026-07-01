import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/providers/theme_controller.dart';
import '../core/notch/overlay/notch_overlay_manager.dart';
import '../core/widgets/keyboard_cat.dart';
import '../shared/widgets/paw_background.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root widget. Wires the Material 3 theme to the GoRouter configuration and
/// puts the drifting paw background behind every route.
class NekoApp extends ConsumerWidget {
  const NekoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    // Watching the theme keeps AppColors.palette current and rebuilds the
    // Material theme (and the paw background) when the user switches themes.
    ref.watch(themeControllerProvider);
    return MaterialApp.router(
      title: 'Neko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => Consumer(
        builder: (context, ref, _) {
          ref.watch(themeControllerProvider);
          // The notch pill floats above the app (and every route/dialog); the
          // paw background + app sit beneath it.
          return NotchOverlayManager(
            child: PawBackground(
              child: KeyboardCat(child: child ?? const SizedBox.shrink()),
            ),
          );
        },
      ),
    );
  }
}
