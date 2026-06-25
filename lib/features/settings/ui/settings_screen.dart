import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/widgets/neko_pill_button.dart';
import '../../auth/providers/auth_provider.dart';

/// The Settings tab. Background and bottom nav pill are provided by [MainShell].
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLoading = ref.watch(
      authControllerProvider.select((s) => s.isLoading),
    );
    final String? email = ref.watch(
      authStateChangesProvider.select((v) => v.valueOrNull?.email),
    );

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Settings', style: AppTextStyles.displayLarge),
            const SizedBox(height: 8),
            if (email != null)
              Text(
                'Signed in as $email',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            const Spacer(),
            NekoPillButton(
              label: 'Sign out',
              isLoading: isLoading,
              onPressed: () {
                unawaited(ref.read(feedbackServiceProvider).onTap());
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
