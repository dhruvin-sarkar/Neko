import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

/// The primary call-to-action, with the Duolingo "3D" press feel: the face
/// sits 4px above a darker platform, and pressing slides it down onto the
/// platform so it feels like a real button being pushed.
///
/// This is presentation only — the caller's [onPressed] is where I fire the
/// haptic/sound feedback, so the feedback map stays in one place.
class NekoPrimaryButton extends StatefulWidget {
  const NekoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.isLoading = false,
    this.color = AppColors.primary,
    this.shadowColor = AppColors.primaryDark,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;
  final Color color;
  final Color shadowColor;
  final IconData? icon;
  final double height;

  @override
  State<NekoPrimaryButton> createState() => _NekoPrimaryButtonState();
}

class _NekoPrimaryButtonState extends State<NekoPrimaryButton> {
  bool _pressed = false;

  bool get _interactive =>
      widget.enabled && !widget.isLoading && widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final Color face = _interactive ? widget.color : AppColors.cloudGray;
    final Color platform = _interactive ? widget.shadowColor : AppColors.silver;
    final bool down = _pressed || !_interactive;

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _interactive ? (_) => _setPressed(true) : null,
        onTapUp: _interactive
            ? (_) {
                _setPressed(false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _interactive ? () => _setPressed(false) : null,
        child: SizedBox(
          width: double.infinity,
          height: widget.height + 4,
          child: Stack(
            children: [
              // The platform — the darker layer the face rests on.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    color: platform,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
              // The face — slides down onto the platform when pressed.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                top: down ? 4 : 0,
                child: Container(
                  height: widget.height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: _content(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (widget.isLoading) {
      return const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
      );
    }
    final IconData? icon = widget.icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: AppSpacing.x8),
        ],
        Text(widget.label.toUpperCase(), style: AppTextStyles.buttonLabel),
      ],
    );
  }
}
