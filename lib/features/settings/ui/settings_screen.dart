import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/widgets/neko_pill_button.dart';
import '../../auth/providers/auth_provider.dart';

/// The Settings tab. Background and bottom nav pill are provided by [MainShell].
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    unawaited(ref.read(feedbackServiceProvider).onTap());
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Sign out?', style: AppTextStyles.headlineLarge),
        content: Text(
          'You can always sign back in with your account.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Sign out',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surface a failed sign-out (e.g. no network) instead of silently doing
    // nothing. A success flows through authStateChanges → router redirect.
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        final Object error = next.error;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error is AppException ? error.message : 'Something went wrong.',
              ),
            ),
          );
      }
    });

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
              onPressed: () => _confirmSignOut(context, ref),
            ),
          ],
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }
}
