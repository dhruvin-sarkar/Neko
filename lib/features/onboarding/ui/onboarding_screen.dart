import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/onboarding_provider.dart';
import 'onboarding_flow_view.dart';
import 'steps/welcome_step.dart';

/// Host for the onboarding flow. Cross-fades between the welcome step and the
/// question flow; the flow view owns the per-step slide transitions.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isWelcome = ref.watch(
      onboardingNotifierProvider.select((s) => s.step == 0),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: isWelcome
          ? const WelcomeStep(key: ValueKey<String>('welcome'))
          : const OnboardingFlowView(key: ValueKey<String>('flow')),
    );
  }
}
