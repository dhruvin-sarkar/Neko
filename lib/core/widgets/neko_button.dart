import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../services/audio_service.dart';

/// The kinds of [NekoButton]. Each shares the same press physics.
enum _NekoButtonKind { primary, secondary, ghost, icon }

/// The app's tactile button: a raised surface sitting on a darker platform that
/// presses down when tapped, then springs back with a slight overshoot — the
/// Duolingo "chiclet" feel, hand-built so it works for labels and icons alike.
///
/// Press drops the surface onto the platform (120ms) and shrinks it slightly;
/// release runs a spring back to rest. Haptics and a click sound fire on every
/// interaction. The touch target is always at least 48dp tall (WCAG).
class NekoButton extends StatefulWidget {
  const NekoButton._({
    required _NekoButtonKind kind,
    required this.onTap,
    this.label,
    this.icon,
    this.leadingIcon,
    this.color,
    this.expand = true,
  }) : _kind = kind;

  /// Filled coral call-to-action.
  factory NekoButton.primary({
    required String label,
    required VoidCallback? onTap,
    bool expand = true,
    Color? color,
    IconData? icon,
  }) => NekoButton._(
    kind: _NekoButtonKind.primary,
    label: label,
    onTap: onTap,
    expand: expand,
    color: color,
    leadingIcon: icon,
  );

  /// Light surface with coral text — secondary actions.
  factory NekoButton.secondary({
    required String label,
    required VoidCallback? onTap,
    bool expand = true,
    IconData? icon,
  }) => NekoButton._(
    kind: _NekoButtonKind.secondary,
    label: label,
    onTap: onTap,
    expand: expand,
    leadingIcon: icon,
  );

  /// Text-only action with just the spring scale (no platform).
  factory NekoButton.ghost({
    required String label,
    required VoidCallback? onTap,
  }) => NekoButton._(
    kind: _NekoButtonKind.ghost,
    label: label,
    onTap: onTap,
    expand: false,
  );

  /// Circular icon button that keeps the platform press.
  factory NekoButton.icon({
    required Widget icon,
    required VoidCallback? onTap,
    Color? color,
  }) => NekoButton._(
    kind: _NekoButtonKind.icon,
    icon: icon,
    onTap: onTap,
    expand: false,
    color: color,
  );

  final _NekoButtonKind _kind;
  final String? label;
  final Widget? icon;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final Color? color;
  final bool expand;

  @override
  State<NekoButton> createState() => _NekoButtonState();
}

class _NekoButtonState extends State<NekoButton>
    with SingleTickerProviderStateMixin {
  // 1.0 = fully raised (rest), 0.0 = pressed down onto the platform. The spring
  // can briefly overshoot past 1.0, which is what gives the satisfying pop.
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  static const double _depth = 4;
  static const double _radius = 16;
  static const double _minHeight = 52; // ≥ 48dp target including the platform

  static final SpringDescription _spring = SpringDescription(
    mass: 1,
    stiffness: 500,
    damping: 28,
  );

  bool get _enabled => widget.onTap != null;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
    AudioService.playClick();
    _c.animateTo(
      0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeIn,
    );
  }

  void _release() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    _c.animateWith(SpringSimulation(_spring, _c.value, 1, 0));
  }

  void _onTapUp(_) {
    _release();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget._kind == _NekoButtonKind.ghost) return _buildGhost();

    final bool isIcon = widget._kind == _NekoButtonKind.icon;
    final Color surface = _surfaceColor();
    final Color platform = _platformColor(surface);

    final Widget content = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final double t = _c.value;
        final double offsetY = (1 - t) * _depth;
        final double scale = 0.97 + (t.clamp(0.0, 1.2)) * 0.03;
        final BorderRadius radius = BorderRadius.circular(
          isIcon ? 100 : _radius,
        );

        return SizedBox(
          height: _minHeight,
          width: isIcon ? _minHeight : null,
          child: Stack(
            children: [
              // Darker platform sits one step below the surface.
              Positioned(
                left: 0,
                right: 0,
                top: _depth,
                height: _minHeight - _depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: platform,
                    borderRadius: radius,
                  ),
                ),
              ),
              // Raised surface, translated down + scaled as it's pressed.
              Positioned(
                left: 0,
                right: 0,
                top: offsetY,
                height: _minHeight - _depth,
                child: Transform.scale(
                  scale: scale,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: radius,
                    ),
                    child: Center(child: _innerContent()),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    final Widget sized = widget.expand
        ? SizedBox(width: double.infinity, child: content)
        : content;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _release,
      behavior: HitTestBehavior.opaque,
      child: sized,
    );
  }

  Widget _innerContent() {
    if (widget._kind == _NekoButtonKind.icon) {
      return IconTheme(
        data: IconThemeData(color: _foregroundColor(), size: 22),
        child: widget.icon!,
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.leadingIcon != null) ...[
            Icon(widget.leadingIcon, color: _foregroundColor(), size: 20),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              widget.label!.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.buttonLabel.copyWith(
                color: _foregroundColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGhost() {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _release,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final double scale = 0.97 + (_c.value.clamp(0.0, 1.2)) * 0.03;
          return Transform.scale(scale: scale, child: child);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(
            widget.label!,
            style: AppTextStyles.buttonLabel.copyWith(
              color: _enabled ? AppColors.primary : AppColors.silver,
            ),
          ),
        ),
      ),
    );
  }

  Color _surfaceColor() {
    if (!_enabled) return AppColors.cloudGray;
    switch (widget._kind) {
      case _NekoButtonKind.primary:
      case _NekoButtonKind.icon:
        return widget.color ?? AppColors.primary;
      case _NekoButtonKind.secondary:
        return AppColors.snowWhite;
      case _NekoButtonKind.ghost:
        return Colors.transparent;
    }
  }

  /// The platform is the surface darkened in HSL space by 0.22 lightness.
  Color _platformColor(Color surface) {
    if (!_enabled) return AppColors.silver;
    if (widget._kind == _NekoButtonKind.secondary) return AppColors.cloudGray;
    final HSLColor hsl = HSLColor.fromColor(surface);
    return hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
  }

  Color _foregroundColor() {
    if (!_enabled) return AppColors.graphite;
    switch (widget._kind) {
      case _NekoButtonKind.secondary:
        return AppColors.primary;
      case _NekoButtonKind.primary:
      case _NekoButtonKind.icon:
      case _NekoButtonKind.ghost:
        return Colors.white;
    }
  }
}
