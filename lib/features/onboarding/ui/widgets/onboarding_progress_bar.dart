import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: Alignment.centerLeft,
          widthFactor: fraction.clamp(0.0, 1.0),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(100)),
            ),
          ),
        ),
      ),
    );
  }
}
