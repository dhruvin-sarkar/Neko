import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_responsive.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/neko_motion.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/widgets/neko_mascot.dart';
import '../../../core/widgets/neko_button.dart';
import '../../../shared/widgets/neko_text_button.dart';

/// The first screen a signed-out person sees: the Neko welcome, with "Get
/// started" leading into account creation and a link to sign in.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FeedbackService feedback = ref.read(feedbackServiceProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: AppResponsive.screenPadding(context),
          child: Column(
            children: [
              const Expanded(child: Center(child: _WelcomeMark())),
              NekoButton.primary(
                label: 'Get started',
                onPressed: () {
                  unawaited(feedback.onTap());
                  context.go(Routes.register);
                },
              ),
              const SizedBox(height: 8),
              NekoTextButton(
                label: 'I already have an account',
                onPressed: () {
                  unawaited(feedback.onTap());
                  context.go(Routes.login);
                },
              ),
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
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
      ),
      // The app's own paw art, not the stock Material glyph — this is the
      // brand's first moment, so even the fallback stays on-brand.
      child: Image.asset(
        'assets/images/paw.png',
        width: 72,
        height: 72,
        color: AppColors.primary,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NekoMascot(size: 132, fallback: fallback).animate().scaleXY(
          begin: 0.6,
          end: 1.0,
          duration: 600.ms,
          curve: NekoMotion.pop,
        ),
        const SizedBox(height: 32),
        Text('Meet Neko.', style: AppTextStyles.displayLarge)
            .animate(delay: 200.ms)
            .fadeIn(duration: 300.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
              'Your cat’s new best friend.',
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
