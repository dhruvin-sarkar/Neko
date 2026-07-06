import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/neko_motion.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../models/activity_option.dart';
import 'selection_check.dart';

/// A tall selectable card for the activity step: an icon tile on the left, a
/// title and description on the right, and a check when selected.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ActivityOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: isSelected,
      semanticLabel: '${option.label}. ${option.description}',
      child: AnimatedContainer(
        duration: NekoMotion.fast,
        curve: NekoMotion.standardCurve,
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.snowWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cloudGray,
            width: isSelected ? 2.5 : 2,
          ),
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color: AppColors.cloudGray.withValues(alpha: 0.8),
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.label, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SelectionCheck(visible: isSelected),
          ],
        ),
      ),
    );
  }
}
