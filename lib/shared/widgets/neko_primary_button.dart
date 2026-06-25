import 'package:chiclet/chiclet.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// The primary full-width call-to-action, built on Chiclet's raised "island"
/// button for the Duolingo 3D depth-press feel.
///
/// Presentation only — callers pass an [onPressed] that already wires in
/// haptic/sound feedback. Disabled (or loading) renders the grey resting state
/// and ignores taps.
class NekoPrimaryButton extends StatelessWidget {
  const NekoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool interactive = enabled && !isLoading && onPressed != null;

    return ChicletAnimatedButton(
      onPressed: interactive ? onPressed : null,
      width: double.infinity,
      height: 56,
      buttonHeight: 5,
      borderRadius: 16,
      backgroundColor: AppColors.primary,
      buttonColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.disabledBtn,
      disabledForegroundColor: Colors.white,
      child: isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : Text(
              label,
              style: AppTextStyles.buttonLabel.copyWith(color: Colors.white),
            ),
    );
  }
}
