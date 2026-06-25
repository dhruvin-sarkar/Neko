import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/pressable.dart';

/// The "add another cat" affordance below the cat list: a sleeping-cat
/// illustration with a coral plus button.
class AddCatSection extends StatelessWidget {
  const AddCatSection({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Image.asset(
            'assets/images/sleeping_cat.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.nightlight_round,
              size: 72,
              color: AppColors.darkBanner.withValues(alpha: 0.4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Pressable(
          onTap: onTap,
          semanticLabel: 'Add a cat',
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Add a cat',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
