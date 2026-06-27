import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

/// A full-width selectable row for the onboarding choices (breed, etc.).
///
/// Unselected it's a white card with a soft flat shadow; selected it snaps to a
/// coral border and tint with a checkmark popping in. Presentation only — the
/// caller's [onTap] fires the selection feedback.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leading,
    this.sublabel,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? leading;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    final Widget? leadingWidget = leading;
    final String? sub = sublabel;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: sub != null ? 72 : 60,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x16,
            vertical: AppSpacing.x12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.snowWhite,
            borderRadius: BorderRadius.circular(AppRadius.md),
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
            children: [
              if (leadingWidget != null) ...[
                leadingWidget,
                const SizedBox(width: AppSpacing.x12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.almostBlack,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (sub != null) Text(sub, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              AnimatedScale(
                scale: isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
