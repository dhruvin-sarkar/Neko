import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// App-wide snackbar helper. Shows a floating, rounded snackbar that slides and
/// fades in, with a leading icon that reflects success vs. error. Using this
/// everywhere keeps transient messaging consistent and premium.
abstract final class NekoSnackBar {
  const NekoSnackBar._();

  /// Shows [message]. Set [error] for error styling (a warning icon).
  static void show(
    BuildContext context,
    String message, {
    bool error = false,
  }) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(_build(message, error: error));
  }

  static SnackBar _build(String message, {required bool error}) {
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.darkBanner,
      elevation: 6,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Row(
        children: <Widget>[
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_outline,
            color: error ? AppColors.primary : Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
