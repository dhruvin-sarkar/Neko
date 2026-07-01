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
    // Re-wash the backdrop the instant a coat is chosen. Watching the theme
    // rebuilds this widget; PawBackground is intentionally NOT const so that
    // rebuild reaches it. A const child is canonicalized to a single identical
    // instance, which Element.updateChild skips — freezing the background on the
    // colour it had when onboarding first mounted (the reported bug).
    ref.watch(themeControllerProvider);
    // ignore: prefer_const_constructors
    return PawBackground(child: const OnboardingFlowView());
  }
}
