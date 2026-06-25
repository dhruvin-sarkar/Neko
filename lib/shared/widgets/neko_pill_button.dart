import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../motion/springs.dart';

/// The primary call-to-action button.
///
/// Presses compress the button to 0.96 immediately, then spring back with a
/// slight overshoot ([Springs.nekoBounce]) — the overshoot is what makes the
/// tap feel satisfying. The fill animates between the coral enabled state and
/// the grey disabled state over 200ms, and carries the flat "Duolingo depth"
/// drop-shadow while enabled.
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

class _NekoPillButtonState extends State<NekoPillButton>
    with SingleTickerProviderStateMixin {
  // Unbounded so the spring can briefly pass 1.0 for the overshoot pop.
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );

  bool get _interactive =>
      widget.enabled && widget.onPressed != null && !widget.isLoading;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _pressDown() => _press.animateTo(
    1,
    duration: const Duration(milliseconds: 80),
    curve: Curves.easeOut,
  );

  void _springBack() => _press.animateWith(
    SpringSimulation(Springs.nekoBounce, _press.value, 0, 0),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _interactive ? (_) => _pressDown() : null,
        onTapUp: _interactive
            ? (_) {
                _springBack();
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _interactive ? _springBack : null,
        child: AnimatedBuilder(
          animation: _press,
          builder: (context, child) {
            final double scale = (1 - 0.04 * _press.value).clamp(0.9, 1.06);
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 56,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _interactive ? AppColors.primary : AppColors.disabledBtn,
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
          ),
        ),
      ),
    );
  }
}
