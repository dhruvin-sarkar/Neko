import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return MaterialApp.router(
      title: 'Neko',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) =>
          PawBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
