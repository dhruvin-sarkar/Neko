import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../onboarding/data/avatar_presets.dart';

/// Circular cat avatar. Resolution order: uploaded photo (network) → bundled
/// preset avatar (asset) → a solid circle in the cat's coat color with a white
/// ring. Every source degrades to the coat-color fallback on error.
class CatAvatar extends StatelessWidget {
  const CatAvatar({
    super.key,
    required this.colorType,
    this.photoUrl,
    this.avatarPreset,
    this.size = 48,
    this.borderWidth = 2,
  });

  final String colorType;
  final String? photoUrl;
  final String? avatarPreset;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.catColorFor(colorType),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: borderWidth),
      ),
    );

    final String? url = photoUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => fallback,
          errorWidget: (_, _, _) => fallback,
        ),
      );
    }

    if (AvatarPresets.isPreset(avatarPreset)) {
      return ClipOval(
        child: Image.asset(
          AvatarPresets.assetFor(avatarPreset ?? ''),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }

    return fallback;
  }
}
