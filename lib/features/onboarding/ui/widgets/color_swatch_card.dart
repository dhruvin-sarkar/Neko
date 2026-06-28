import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/neko_palette.dart';
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
                    const SizedBox(height: 10),
                    Text(option.label, style: AppTextStyles.bodyMedium),
                    if (option.themeId != null) ...[
                      const SizedBox(height: 8),
                      _MiniPalette(themeId: option.themeId!),
                    ],
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

/// A row of five tiny circles previewing a theme's key colours: primary,
/// secondary, background, surface, and the nav accent.
class _MiniPalette extends StatelessWidget {
  const _MiniPalette({required this.themeId});

  final String themeId;

  @override
  Widget build(BuildContext context) {
    final NekoPalette p = NekoPalettes.byId(themeId);
    final List<Color> colors = <Color>[
      p.primary,
      p.secondary,
      p.background,
      p.surface,
      p.navActive,
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final Color c in colors)
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
          ),
      ],
    );
  }
}
