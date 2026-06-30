import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/neko_palette.dart';
import '../../../../core/neko_motion.dart';
import '../../../../shared/widgets/pressable.dart';
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
    return Pressable(
      onTap: onTap,
      semanticLabel: option.label,
      selected: isSelected,
      child: AnimatedContainer(
        duration: NekoMotion.fast,
        curve: NekoMotion.standardCurve,
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
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // A clear selection ring around (not on) the coat, so it
                        // stays visible against any coat colour or gradient. It
                        // grows + fades in with the card tint rather than popping.
                        AnimatedScale(
                          scale: isSelected ? 1.0 : 0.85,
                          duration: NekoMotion.fast,
                          curve: NekoMotion.standardCurve,
                          child: AnimatedOpacity(
                            opacity: isSelected ? 1.0 : 0.0,
                            duration: NekoMotion.fast,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _gradient(option.themeId) == null
                                ? option.circleColor
                                : null,
                            gradient: _gradient(option.themeId),
                            shape: BoxShape.circle,
                            border: option.needsBorder
                                ? Border.all(color: AppColors.border)
                                : null,
                          ),
                        ),
                      ],
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
    );
  }
}

/// Multi-tone swatch gradients for the patterned coats; null = solid colour.
Gradient? _gradient(String? themeId) {
  switch (themeId) {
    case 'calico':
      return const SweepGradient(
        colors: [
          Color(0xFFF15A29),
          Color(0xFF1A1A2E),
          Color(0xFFFFFFFF),
          Color(0xFFF15A29),
        ],
      );
    case 'tortoiseshell':
      return const SweepGradient(
        colors: [
          Color(0xFFC0632A),
          Color(0xFF3E1A00),
          Color(0xFFD4A017),
          Color(0xFFC0632A),
        ],
      );
    case 'tuxedo':
      return const LinearGradient(
        colors: [
          Color(0xFF212121),
          Color(0xFF212121),
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
        ],
        stops: [0.0, 0.5, 0.5, 1.0],
      );
    default:
      return null;
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
