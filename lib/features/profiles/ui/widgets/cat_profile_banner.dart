import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/pressable.dart';
import '../../../onboarding/models/cat_profile.dart';
import 'cat_avatar.dart';

/// A pill-shaped banner for a single cat on the home screen.
class CatProfileBanner extends StatelessWidget {
  const CatProfileBanner({super.key, required this.cat, required this.onTap});

  final CatProfile cat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '${cat.name}, ${cat.breed}',
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.darkBanner,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Row(
          children: [
            CatAvatar(
              colorType: cat.colorType,
              catId: cat.id,
              avatarPreset: cat.avatarPreset,
              heroTag: 'cat-avatar-${cat.id}',
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    cat.breed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
