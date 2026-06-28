import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/pressable.dart';

/// The "add another cat" button: the sleeping-cat illustration with a coral
/// plus over its lower-left. The whole illustration is tappable.
class AddCatSection extends StatelessWidget {
  const AddCatSection({super.key, required this.onTap, this.plusKey});

  final VoidCallback onTap;

  /// Optional key used by the guided tour to spotlight the "+" button.
  final Key? plusKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Pressable(
        onTap: onTap,
        semanticLabel: 'Add a cat',
        child: SizedBox(
          width: 300,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RepaintBoundary(
                child: Lottie.asset(
                  'assets/animations/Sleeping Cat Breathing Loop.json',
                  fit: BoxFit.contain,
                  repeat: !MediaQuery.disableAnimationsOf(context),
                  frameRate: FrameRate.max,
                  errorBuilder: (_, _, _) => const _MatPlaceholder(),
                ),
              ),
              Align(
                alignment: const Alignment(-0.55, 0.55),
                child: Container(
                  key: plusKey,
                  width: 52,
                  height: 52,
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
                  child: Icon(
                    Icons.add_rounded,
                    color: AppColors.textOnPrimary,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The mat I draw if the sleeping-cat image fails to load.
class _MatPlaceholder extends StatelessWidget {
  const _MatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.darkBanner.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.bedtime_rounded,
        size: 64,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }
}
