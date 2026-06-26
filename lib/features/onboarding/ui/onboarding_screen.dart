import 'package:flutter/material.dart';

import 'onboarding_flow_view.dart';

/// Host for the onboarding flow. The brand welcome now lives on the pre-auth
/// Welcome screen, so onboarding goes straight into the questions.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) => const OnboardingFlowView();
}
