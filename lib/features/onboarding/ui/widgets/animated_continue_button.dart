import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/neko_motion.dart';
import '../../../../core/widgets/neko_button.dart';

/// The onboarding continue button: a primary button that gives a spring
/// scale-pop the moment it first becomes enabled, signalling "you can move on
/// now".
class AnimatedContinueButton extends StatefulWidget {
  const AnimatedContinueButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
    this.isLoading = false,
    this.color,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;

  @override
  State<AnimatedContinueButton> createState() => _AnimatedContinueButtonState();
}

class _AnimatedContinueButtonState extends State<AnimatedContinueButton> {
  // Bumped on each disabled->enabled transition to replay the pop exactly once.
  int _enablePulse = 0;

  @override
  void didUpdateWidget(AnimatedContinueButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.enabled && widget.enabled) _enablePulse++;
  }

  @override
  Widget build(BuildContext context) {
    return NekoButton.primary(
          label: widget.label,
          enabled: widget.enabled,
          isLoading: widget.isLoading,
          onPressed: widget.onPressed,
          color: widget.color,
        )
        .animate(key: ValueKey<int>(_enablePulse))
        .scaleXY(
          begin: widget.enabled ? 0.95 : 1.0,
          end: 1.0,
          duration: NekoMotion.quick,
          curve: NekoMotion.pop,
        );
  }
}
