import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../onboarding/data/avatar_presets.dart';

/// Circular cat avatar. Resolves an on-device photo (by [catId]), then a preset
/// asset, then a solid coat-colour circle; every source falls back to the coat
/// colour on error.
class CatAvatar extends StatelessWidget {
  const CatAvatar({
    super.key,
    required this.colorType,
    this.catId,
    this.avatarPreset,
    this.size = 48,
    this.borderWidth = 2,
    this.heroTag,
  });

  final String colorType;

  /// The cat's id, used to resolve its on-device profile photo (if any).
  final String? catId;
  final String? avatarPreset;
  final double size;
  final double borderWidth;

  /// When set, the avatar joins a Hero shared-element transition.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = _buildAvatar();
    if (heroTag == null) return avatar;
    return Hero(
      tag: heroTag!,
      // Stay circular and crisp during the flight.
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

    final String? id = catId;
    final String? path = id == null
        ? null
        : LocalStorageService.profilePicturePathSync(id);
    if (path != null && path.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Downsample to ~3x logical size so a 1024px source never decodes at
          // full resolution into memory for a small avatar.
          cacheWidth: (size * 3).round(),
          cacheHeight: (size * 3).round(),
          errorBuilder: (_, _, _) => fallback,
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
