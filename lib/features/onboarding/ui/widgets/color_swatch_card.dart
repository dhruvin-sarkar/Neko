import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../models/coat_option.dart';
import 'selection_check.dart';

/// A square coat-color card: a large color circle above its label, with a
/// coral border and a corner check when selected.
class ColorSwatchCard extends StatelessWidget {
  const ColorSwatchCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final CoatOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.selectedFill : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.selectedBorder : AppColors.border,
              width: isSelected ? 3 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: option.circleColor,
                        shape: BoxShape.circle,
                        border: option.needsBorder
                            ? Border.all(color: AppColors.border)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(option.label, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: SelectionCheck(visible: isSelected),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
