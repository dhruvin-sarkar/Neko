import 'package:chiclet/chiclet.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

/// The app's single call-to-action button — a 3D "chiclet" that presses down
/// onto a darker platform (the Duolingo feel), built on the `chiclet` package.
///
/// Variants:
/// - [NekoButton.primary]   — the coral CTA.
/// - [NekoButton.secondary] — a lighter surface chiclet with coral label.
/// - [NekoButton.ghost]     — a low-emphasis text action (no platform).
///
/// Presentation only: callers fire feedback in their `onPressed`, so the
/// feedback map stays in one place. Labels render uppercase (except ghost).
class NekoButton extends StatelessWidget {
  const NekoButton._({
    super.key,
    required _NekoVariant variant,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
    this.icon,
    this.color,
    this.expand = true,
  }) : _variant = variant;

  /// The coral primary call-to-action.
  factory NekoButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool enabled = true,
    bool isLoading = false,
    IconData? icon,
    Color? color,
    bool expand = true,
  }) => NekoButton._(
    key: key,
    variant: _NekoVariant.primary,
    label: label,
    onPressed: onPressed,
    enabled: enabled,
    isLoading: isLoading,
    icon: icon,
    color: color,
    expand: expand,
  );

  /// A lighter surface chiclet (white face, coral label) for secondary actions.
  factory NekoButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool enabled = true,
    bool isLoading = false,
    IconData? icon,
    bool expand = true,
  }) => NekoButton._(
    key: key,
    variant: _NekoVariant.secondary,
    label: label,
    onPressed: onPressed,
    enabled: enabled,
    isLoading: isLoading,
    icon: icon,
    expand: expand,
  );

  /// A low-emphasis text action with a ripple — no platform.
  factory NekoButton.ghost({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) => NekoButton._(
    key: key,
    variant: _NekoVariant.ghost,
    label: label,
    onPressed: onPressed,
    enabled: enabled,
  );

  final _NekoVariant _variant;
  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final bool expand;

  bool get _interactive => enabled && !isLoading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    if (_variant == _NekoVariant.ghost) {
      return _GhostButton(
        label: label,
        onPressed: onPressed,
        interactive: _interactive,
      );
    }

    final bool primary = _variant == _NekoVariant.primary;
    final Color face = primary
        ? (color ?? AppColors.primary)
        : AppColors.snowWhite;
    final Color platform = primary
        ? (color != null ? _darken(color!) : AppColors.primaryDark)
        : AppColors.cloudGray;
    final Color fg = primary ? AppColors.textOnPrimary : AppColors.primary;

    return ChicletAnimatedButton(
      onPressed: _interactive ? onPressed : null,
      width: expand ? double.infinity : null,
      height: 56,
      buttonHeight: 5,
      borderRadius: AppRadius.lg,
      backgroundColor: _interactive ? face : AppColors.cloudGray,
      buttonColor: _interactive ? platform : AppColors.silver,
      foregroundColor: fg,
      disabledBackgroundColor: AppColors.cloudGray,
      disabledForegroundColor: AppColors.graphite,
      child: isLoading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: _interactive ? fg : AppColors.graphite,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.x8),
                ],
                Flexible(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.buttonLabel.copyWith(
                      color: _interactive ? fg : AppColors.graphite,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Darkens [c] in HSL space for the pressed-platform colour of a custom-tinted
  /// primary button.
  static Color _darken(Color c) {
    final HSLColor hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
  }
}

enum _NekoVariant { primary, secondary, ghost }

/// A low-emphasis text action with a ripple — no platform. Extracted to its own
/// widget so it composes cleanly (no Widget-returning helper method).
class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.onPressed,
    required this.interactive,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: interactive,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: interactive ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x16,
              vertical: AppSpacing.x12,
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.buttonLabel.copyWith(
                color: interactive ? AppColors.primary : AppColors.silver,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
