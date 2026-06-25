import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../shared/motion/springs.dart';
import '../../../../shared/widgets/neko_pill_button.dart';
import '../../../../shared/widgets/neko_text_button.dart';
import '../../providers/onboarding_provider.dart';

/// Step 0 — the warm welcome. White screen, a mark that springs in, and the
/// two entry actions.
class WelcomeStep extends ConsumerStatefulWidget {
  const WelcomeStep({super.key});

  @override
  ConsumerState<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends ConsumerState<WelcomeStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scale = AnimationController.unbounded(
    vsync: this,
    value: 0.7,
  );

  @override
  void initState() {
    super.initState();
    _scale.animateWith(SpringSimulation(Springs.nekoBounce, 0.7, 1.0, 0));
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAuthed =
        ref.watch(authStateChangesProvider).valueOrNull != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _scale,
                    builder: (context, child) =>
                        Transform.scale(scale: _scale.value, child: child),
                    child: const _WelcomeMark(),
                  ),
                ),
              ),
              NekoPillButton(
                label: 'Get started',
                onPressed: ref
                    .read(onboardingNotifierProvider.notifier)
                    .nextStep,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            color: AppColors.selectedFill,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pets_rounded,
            size: 64,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 32),
        Text('Meet Neko.', style: AppTextStyles.displayLarge),
        const SizedBox(height: 8),
        Text(
          "Your cat's new best friend.",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
