import 'package:flutter/material.dart';

import '../../../shared/widgets/paw_background.dart';
import 'onboarding_flow_view.dart';

/// Host for the onboarding flow. The brand welcome now lives on the pre-auth
/// Welcome screen, so onboarding goes straight into the questions.
///
/// Wraps the flow in its own opaque [PawBackground]. Onboarding can be pushed
/// on top of the live Home shell (when adding another cat); the opaque backdrop
/// fully occludes Home so it never shows through the transparent scaffold.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PawBackground(child: OnboardingFlowView());
}
