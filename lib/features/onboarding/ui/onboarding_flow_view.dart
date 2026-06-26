import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/motion/page_transitions.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/widgets/neko_snackbar.dart';
import '../models/step_config.dart';
import '../providers/onboarding_provider.dart';
import 'steps/activity_step.dart';
import 'steps/age_step.dart';
import 'steps/breed_step.dart';
import 'steps/coat_color_step.dart';
import 'steps/name_step.dart';
import 'steps/photo_step.dart';
import 'steps/weight_step.dart';
import 'widgets/animated_continue_button.dart';
import 'widgets/onboarding_top_bar.dart';

/// The chrome for the question steps: back arrow, progress bar, the sliding
/// step content, and the continue button. Owns advancing and the final save,
/// and fires the confetti celebration when the cat is saved.
class OnboardingFlowView extends ConsumerStatefulWidget {
  const OnboardingFlowView({super.key});

  @override
  ConsumerState<OnboardingFlowView> createState() => _OnboardingFlowViewState();
}

class _OnboardingFlowViewState extends ConsumerState<OnboardingFlowView> {
  int _lastStep = 1;
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _onContinue(StepConfig config) async {
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final FeedbackService feedback = ref.read(feedbackServiceProvider);
    if (!config.isFinal) {
      unawaited(feedback.onAdvance());
      notifier.nextStep();
      return;
    }
    // Final step: save first, then celebrate before the curtain sweeps us home.
    final bool saved = await notifier.save();
    if (!mounted || !saved) return;
    unawaited(feedback.onSuccess());
    _confetti.play();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    // Branded paw-curtain hands off to Home: it covers the screen, we navigate
    // underneath, then it sweeps open to reveal the app.
    await playPawCurtain(
      context,
      onCovered: () {
        if (mounted) context.go(Routes.home);
      },
    );
  }

  /// The back arrow goes to the previous question, or — if we're already on the
  /// first one — exits onboarding entirely (e.g. cancelling "add another cat"
  /// and returning to Home).
  void _onBack() {
    if (ref.read(onboardingNotifierProvider).step > 1) {
      ref.read(onboardingNotifierProvider.notifier).previousStep();
    } else if (context.canPop()) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(
      onboardingNotifierProvider.select((s) => s.errorMessage),
      (previous, next) {
        if (next != null && next.isNotEmpty) {
          unawaited(ref.read(feedbackServiceProvider).onError());
          NekoSnackBar.show(context, next, error: true);
        }
      },
    );

    final state = ref.watch(onboardingNotifierProvider);
    final StepConfig config = stepConfigOf(state);
    final bool forward = state.step >= _lastStep;
    _lastStep = state.step;
    final notifier = ref.read(onboardingNotifierProvider.notifier);

    return PopScope(
      canPop: state.step <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) notifier.previousStep();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    OnboardingTopBar(
                      onBack: _onBack,
                      showProgress: config.showProgress,
                      fraction: config.progressFraction,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
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
                                  begin: Offset(begin, 0),
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
                            2 => const PhotoStep(),
                            3 => const BreedStep(),
                            4 => const AgeStep(),
                            5 => const WeightStep(),
                            6 => const CoatColorStep(),
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
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 30,
                gravity: 0.2,
                emissionFrequency: 0.05,
                colors: const [
                  AppColors.primary,
                  AppColors.success,
                  AppColors.warning,
                  AppColors.info,
                  AppColors.coatGinger,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
