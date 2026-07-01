import 'package:flutter/widgets.dart';

/// Shared visual tokens for the notch content widgets, kept separate from the
/// app's `AppColors` because the pill is always dark (black island), regardless
/// of the app's coat theme.
abstract final class NotchStyle {
  static const Color coral = Color(0xFFFF6B6B);
  static const Color green = Color(0xFF4CAF50);
  static const Color red = Color(0xFFF44336);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFABABAB);
  static const Color track = Color(0xFF333333);

  static const TextStyle primaryLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.2,
    height: 1.1,
  );

  static const TextStyle secondaryLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.1,
  );

  static const EdgeInsets compactPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  static const EdgeInsets expandedPadding = EdgeInsets.all(14);
}
