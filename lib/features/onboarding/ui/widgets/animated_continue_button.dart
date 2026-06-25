import 'package:flutter/material.dart';

import '../../../../shared/widgets/neko_pill_button.dart';

/// The onboarding continue button.
///
/// When [enabled] flips from false to true, it scales up from 0.97 to 1.0 over
/// 200ms while [NekoPillButton] simultaneously animates its fill from grey to
/// coral — the combined effect that signals "you can move on now".
class AnimatedContinueButton extends StatelessWidget {
  const AnimatedContinueButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: enabled ? 1.0 : 0.97,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: NekoPillButton(
        label: label,
        enabled: enabled,
        isLoading: isLoading,
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}
