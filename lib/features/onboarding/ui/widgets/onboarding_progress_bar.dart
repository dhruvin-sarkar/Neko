import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/neko_motion.dart';

/// Thin coral progress bar whose fill width animates as the step changes.
class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({super.key, required this.fraction});

  /// Fill amount from 0.0 to 1.0.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: Container(
        height: 8,
        color: AppColors.cloudGray,
        child: AnimatedFractionallySizedBox(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : NekoMotion.standard,
          curve: NekoMotion.standardCurve,
          alignment: Alignment.centerLeft,
          widthFactor: fraction.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
          ),
        ),
      ),
    );
  }
}
