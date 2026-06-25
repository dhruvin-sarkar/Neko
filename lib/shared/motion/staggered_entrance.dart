import 'package:flutter/material.dart';

/// Fades a child in while sliding it up from [offsetY] logical pixels below
/// its final position, after an optional [delay].
///
/// Built on [TweenAnimationBuilder] so it runs exactly once on first build
/// (the tween animates from its `begin` to its `end` a single time). Wrap each
/// item in a cascading list with `StaggeredEntrance(delay: stagger * index)`
/// to get the Duolingo-style cascade.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offsetY = 24,
    this.curve = Curves.easeOutCubic,
  });

  /// The widget to animate in.
  final Widget child;

  /// How long to wait before this item starts animating.
  final Duration delay;

  /// Duration of the slide-and-fade once it begins.
  final Duration duration;

  /// Distance in logical pixels the child travels upward as it appears.
  final double offsetY;

  /// Easing curve applied to the combined motion.
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + delay,
      // A short head-start interval encodes the per-item delay without timers,
      // so there is nothing to cancel if the widget is disposed mid-flight.
      curve: Interval(_delayFraction, 1, curve: curve),
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * offsetY),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  double get _delayFraction {
    final int total = (duration + delay).inMicroseconds;
    if (total <= 0) return 0;
    return (delay.inMicroseconds / total).clamp(0.0, 0.95);
  }
}
