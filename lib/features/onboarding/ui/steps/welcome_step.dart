import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../shared/services/feedback_service.dart';
import '../../../../shared/widgets/neko_mascot.dart';
import '../../../../shared/widgets/neko_primary_button.dart';
import '../../../../shared/widgets/neko_text_button.dart';
import '../../providers/onboarding_provider.dart';

/// Step 0 — the warm welcome. White screen, a mascot that springs in, and the
/// two entry actions.
class WelcomeStep extends ConsumerWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isAuthed = ref.watch(
      authStateChangesProvider.select((v) => v.valueOrNull != null),
    );
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final FeedbackService feedback = ref.read(feedbackServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Expanded(child: Center(child: _WelcomeMark())),
              NekoPrimaryButton(
                label: 'Get started',
                onPressed: () {
                  unawaited(feedback.onTap());
                  notifier.nextStep();
                },
              ),
              if (!isAuthed) ...[
                const SizedBox(height: 12),
                NekoTextButton(
                  label: 'I already have an account',
                  onPressed: () => context.go(Routes.login),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeMark extends StatelessWidget {
  const _WelcomeMark();

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      width: 132,
      height: 132,
      decoration: const BoxDecoration(
        color: AppColors.selectedFill,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.pets_rounded, size: 64, color: AppColors.primary),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NekoMascot(size: 132, fallback: fallback).animate().scaleXY(
          begin: 0.6,
          end: 1.0,
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: 32),
        Text('Meet Neko.', style: AppTextStyles.displayLarge)
            .animate(delay: 200.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
              "Your cat's new best friend.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            )
            .animate(delay: 300.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }
}
