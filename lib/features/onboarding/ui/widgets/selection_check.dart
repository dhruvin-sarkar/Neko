import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/neko_motion.dart';

/// A coral circle with a white check that pops in when [visible] becomes true,
/// driven by `flutter_animate`'s target so it reverses cleanly on deselect.
class SelectionCheck extends StatelessWidget {
  const SelectionCheck({super.key, required this.visible, this.size = 22});

  final bool visible;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: size * 0.72,
            color: AppColors.textOnPrimary,
          ),
        )
        .animate(target: visible ? 1 : 0)
        .scaleXY(
          begin: 0,
          end: 1,
          duration: NekoMotion.fast,
          curve: NekoMotion.pop,
        )
        .fade(begin: 0, end: 1, duration: NekoMotion.fast);
  }
}
