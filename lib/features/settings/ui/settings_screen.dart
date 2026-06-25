import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/widgets/neko_pill_button.dart';
import '../../auth/providers/auth_provider.dart';

/// Lightweight settings screen. Currently surfaces sign-out; expands in a
/// later milestone.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Routes.home)),
        title: Text('Settings', style: AppTextStyles.headlineLarge),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NekoPillButton(
                label: 'Sign out',
                isLoading: isLoading,
                onPressed: () {
                  unawaited(ref.read(feedbackServiceProvider).onTap());
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          ).animate().fadeIn(duration: 280.ms),
        ),
      ),
    );
  }
}
