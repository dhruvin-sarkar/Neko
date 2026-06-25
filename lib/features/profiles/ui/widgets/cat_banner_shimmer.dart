import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmering placeholder banners shown while cats load — same shape as the
/// real banners so the layout doesn't jump.
class CatBannerShimmer extends StatelessWidget {
  const CatBannerShimmer({super.key, this.count = 2});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          Shimmer.fromColors(
            baseColor: Colors.white.withValues(alpha: 0.35),
            highlightColor: Colors.white.withValues(alpha: 0.65),
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
    );
  }
}
