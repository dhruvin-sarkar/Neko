import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// A coral circle with a white check that pops in when [visible] becomes true.
class SelectionCheck extends StatelessWidget {
  const SelectionCheck({super.key, required this.visible, this.size = 22});

  final bool visible;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: size * 0.72,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
