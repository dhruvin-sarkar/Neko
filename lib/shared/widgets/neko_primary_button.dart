import 'package:chiclet/chiclet.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

/// The primary call-to-action. Built on Chiclet's animated button for the
/// physical 3D press: the coral face sits on a darker platform and pushes down
/// when tapped.
///
/// Presentation only — the caller's [onPressed] is where I fire the feedback,
/// so the feedback map stays in one place. The label renders uppercase.
class NekoPrimaryButton extends StatelessWidget {
  const NekoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
    this.color,
    this.shadowColor,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;
  final Color? color;
  final Color? shadowColor;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool interactive = enabled && !isLoading && onPressed != null;
    final IconData? icon = this.icon;
    final Color faceColor = color ?? AppColors.primary;
    final Color faceShadow = shadowColor ?? AppColors.primaryDark;

    return ChicletAnimatedButton(
      onPressed: interactive ? onPressed : null,
      width: double.infinity,
      height: height,
      buttonHeight: 5,
      borderRadius: AppRadius.lg,
      backgroundColor: interactive ? faceColor : AppColors.cloudGray,
      buttonColor: interactive ? faceShadow : AppColors.silver,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.cloudGray,
      disabledForegroundColor: AppColors.graphite,
      child: isLoading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: AppSpacing.x8),
                ],
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.buttonLabel.copyWith(
                    color: interactive ? Colors.white : AppColors.graphite,
                  ),
                ),
              ],
            ),
    );
  }
}
