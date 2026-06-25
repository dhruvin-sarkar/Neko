import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Time-of-day greeting plus a short subtitle, shown at the top of home.
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key, this.displayName});

  final String? displayName;

  String get _partOfDay {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final String? name = displayName?.trim().split(' ').first;
    final String greeting = (name == null || name.isEmpty)
        ? '$_partOfDay.'
        : '$_partOfDay, $name.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: AppTextStyles.headlineLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here are your cats.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
