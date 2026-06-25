import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// A secondary full-width pill button.
///
/// Presses compress to 0.96 via `flutter_animate`'s target-driven scale, and
/// the fill animates between coral (enabled) and grey (disabled). For the
/// primary call-to-action, use `NekoPrimaryButton` (the Chiclet button).
class NekoPillButton extends StatefulWidget {
  const NekoPillButton({
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
  State<NekoPillButton> createState() => _NekoPillButtonState();
}

class _NekoPillButtonState extends State<NekoPillButton> {
  // Local, ephemeral press state — justified setState (see DECISIONS.md).
  bool _pressed = false;

  bool get _interactive =>
      widget.enabled && widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
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
        child:
            AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  height: 56,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _interactive
                        ? AppColors.primary
                        : AppColors.disabledBtn,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: _interactive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              offset: const Offset(0, 4),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.label,
                          style: AppTextStyles.buttonLabel.copyWith(
                            color: Colors.white,
                          ),
                        ),
                )
                .animate(target: _pressed ? 1 : 0)
                .scaleXY(end: 0.96, duration: 80.ms, curve: Curves.easeOut),
      ),
    );
  }
}
