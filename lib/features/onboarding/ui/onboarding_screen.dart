import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/paw_background.dart';
import '../../settings/providers/theme_controller.dart';
import 'onboarding_flow_view.dart';

/// Host for the onboarding flow. The brand welcome now lives on the pre-auth
/// Welcome screen, so onboarding goes straight into the questions.
///
/// Wraps the flow in its own opaque [PawBackground]. Watching the theme here
/// means the backdrop re-washes to the new colour the instant a coat is chosen
/// on the coat-colour step.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeControllerProvider);
    return const PawBackground(child: OnboardingFlowView());
  }
}
