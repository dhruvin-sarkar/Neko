import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../models/step_config.dart';
import '../providers/onboarding_provider.dart';
import 'steps/activity_step.dart';
import 'steps/age_step.dart';
import 'steps/breed_step.dart';
import 'steps/coat_color_step.dart';
import 'steps/name_step.dart';
import 'steps/weight_step.dart';
import 'widgets/animated_continue_button.dart';
import 'widgets/onboarding_top_bar.dart';

/// The chrome for steps 1–6: back arrow, progress bar, the sliding step
/// content, and the continue button. Owns advancing and the final save.
class OnboardingFlowView extends ConsumerStatefulWidget {
  const OnboardingFlowView({super.key});

  @override
  ConsumerState<OnboardingFlowView> createState() => _OnboardingFlowViewState();
}

class _OnboardingFlowViewState extends ConsumerState<OnboardingFlowView> {
  int _lastStep = 1;

  Future<void> _onContinue(StepConfig config) async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    if (!config.isFinal) {
      notifier.nextStep();
      return;
    }
    final bool saved = await notifier.save();
    if (saved && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      onboardingNotifierProvider.select((s) => s.errorMessage),
      (previous, next) {
        if (next != null && next.isNotEmpty) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(next)));
        }
      },
    );

    final state = ref.watch(onboardingNotifierProvider);
    final StepConfig config = stepConfigOf(state);
    final bool forward = state.step >= _lastStep;
    _lastStep = state.step;
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) notifier.previousStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                OnboardingTopBar(
                  onBack: notifier.previousStep,
                  showProgress: config.showProgress,
                  fraction: config.progressFraction,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      final bool incoming =
                          child.key == ValueKey<int>(state.step);
                      final double begin = incoming
                          ? (forward ? 1 : -1)
                          : (forward ? -1 : 1);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: animation.drive(
                            Tween<Offset>(
                              begin: Offset(begin * 0.18, 0),
                              end: Offset.zero,
                            ).chain(CurveTween(curve: Curves.easeOutCubic)),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(state.step),
                      child: switch (state.step) {
                        1 => const NameStep(),
                        2 => const BreedStep(),
                        3 => const AgeStep(),
                        4 => const WeightStep(),
                        5 => const CoatColorStep(),
                        _ => const ActivityStep(),
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedContinueButton(
                  label: config.continueLabel,
                  enabled: config.canContinue,
                  isLoading: state.isSaving,
                  onPressed: () => _onContinue(config),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
