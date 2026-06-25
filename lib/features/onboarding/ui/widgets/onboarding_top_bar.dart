import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'onboarding_progress_bar.dart';

/// Back arrow plus the step progress bar, shown above each question.
class OnboardingTopBar extends StatelessWidget {
  const OnboardingTopBar({
    super.key,
    required this.onBack,
    required this.showProgress,
    required this.fraction,
  });

  final VoidCallback onBack;
  final bool showProgress;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textPrimary,
            tooltip: 'Back',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: showProgress
                ? RepaintBoundary(
                    child: OnboardingProgressBar(fraction: fraction),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
