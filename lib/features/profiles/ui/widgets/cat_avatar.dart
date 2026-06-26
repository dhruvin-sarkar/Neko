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
    this.heroTag,
  });

  final String colorType;
  final String? photoUrl;
  final String? avatarPreset;
  final double size;
  final double borderWidth;

  /// When set, the avatar participates in a Hero shared-element transition
  /// (e.g. flying from the home banner into the profile detail).
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = _buildAvatar();
    if (heroTag == null) return avatar;
    return Hero(
      tag: heroTag!,
      // Keep the avatar circular and crisp throughout the flight.
      flightShuttleBuilder: (_, _, _, _, toHero) => toHero.widget,
      child: avatar,
    );
  }

  Widget _buildAvatar() {
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
