import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/app_colors.dart';

/// Loading skeleton for the cat profile screen. Mirrors the real layout — round
/// avatar, name/breed lines, then the 2×2 stat grid — so the swap to real
/// content doesn't shift anything.
class ProfileDetailShimmer extends StatelessWidget {
  const ProfileDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget box(double w, double h, [double r = 16]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    Widget statCard() => Expanded(child: box(double.infinity, 96));

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceCard,
        // On dark palettes a white highlight flashes harshly; ease toward the
        // raised surface instead so the sweep stays subtle on every theme.
        highlightColor: AppColors.isDark
            ? AppColors.surfaceElevated
            : (Color.lerp(AppColors.surfaceCard, Colors.white, 0.6) ??
                  Colors.white),
        period: const Duration(milliseconds: 1400),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            Center(
              child: Container(
                width: 112,
                height: 112,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(child: box(160, 28)),
            const SizedBox(height: 10),
            Center(child: box(110, 18)),
            const SizedBox(height: 32),
            Row(children: [statCard(), const SizedBox(width: 16), statCard()]),
            const SizedBox(height: 16),
            Row(children: [statCard(), const SizedBox(width: 16), statCard()]),
          ],
        ),
      ),
    );
  }
}
