import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/app_colors.dart';

/// Shimmering placeholder banners shown while cats load — same shape as the
/// real banners so the layout doesn't jump. Reads theme tokens so it stays calm
/// on the dark palettes instead of flashing white.
class CatBannerShimmer extends StatelessWidget {
  const CatBannerShimmer({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: [
          for (int i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Shimmer.fromColors(
              baseColor: AppColors.surfaceMuted,
              highlightColor: AppColors.surfaceElevated,
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
