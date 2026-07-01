import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controller/notch_controller.dart';
import '../features/battery/battery_content.dart';
import '../features/call/call_content.dart';
import '../features/hey_neko/hey_neko_content.dart';
import '../features/music/music_content.dart';
import '../features/nav/nav_content.dart';
import '../features/notification/notification_content.dart';
import '../features/order/order_content.dart';
import '../features/timer/timer_content.dart';
import '../features/workout/workout_content.dart';
import '../models/notch_activity.dart';
import '../models/notch_state.dart';
import 'notch_idle_content.dart';

/// The in-app pill (Layer 1). A single [AnimatedContainer] morphs between the
/// idle dot, the compact bar, the expanded card and the Hey Neko panel; an
/// [AnimatedSwitcher] cross-fades the content as the activity changes.
class NotchPill extends ConsumerWidget {
  const NotchPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotchState state = ref.watch(notchControllerProvider);
    final NotchController controller = ref.read(
      notchControllerProvider.notifier,
    );
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double topInset = MediaQuery.viewPaddingOf(context).top;
    final _PillDimensions dims = _PillDimensions.forState(state, screenWidth);

    // Sit inside the status-bar zone in idle/compact; drop down from it when the
    // card is taller than the inset. `math.max` keeps the upper clamp bound at
    // or above the 4.0 lower bound — otherwise a thin non-zero inset (landscape,
    // split-screen) would make upper < lower and `clamp` would throw.
    final double maxTop = math.max(4.0, topInset <= 0 ? 8.0 : topInset * 0.6);
    final double topOffset = (topInset - dims.height).clamp(4.0, maxTop);

    // Only interactive when an activity is showing. In idle the pill lets taps
    // fall through to the app beneath and exposes no phantom button to screen
    // readers.
    final bool interactive = state.primary != null;

    return Padding(
      padding: EdgeInsets.only(top: topOffset),
      child: IgnorePointer(
        ignoring: !interactive,
        child: Semantics(
          container: true,
          button: interactive,
          enabled: interactive,
          label: interactive
              ? '${_notchLabel(state.primary)}. '
                    'Double tap to expand, long press to dismiss.'
              : _notchLabel(state.primary),
          onTap: interactive ? controller.onTap : null,
          onLongPress: interactive ? controller.onLongPress : null,
          child: GestureDetector(
            onTap: controller.onTap,
            onLongPress: controller.onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubicEmphasized,
              width: dims.width,
              height: dims.height,
              decoration: BoxDecoration(
                color: _backgroundColor(state.mode),
                borderRadius: BorderRadius.circular(dims.radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder:
                    (Widget child, Animation<double> animation) =>
                        FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.25),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                            child: child,
                          ),
                        ),
                // Key on the activity identity only — NOT the mode — so a pure
                // compact<->expanded transition keeps the content's State (and
                // its timers) instead of tearing it down.
                child: KeyedSubtree(
                  key: ValueKey<String>(
                    state.primary?.runtimeType.toString() ?? 'idle',
                  ),
                  child: _buildContent(state),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _backgroundColor(NotchDisplayMode mode) => switch (mode) {
    NotchDisplayMode.heyNeko => const Color(0xFF0D0D1A),
    NotchDisplayMode.expanded => const Color(0xFF1C1C1E),
    _ => Colors.black,
  };

  String _notchLabel(NotchActivity? primary) {
    if (primary == null) return 'Neko notch, idle';
    final String kind = switch (primary) {
      MusicActivity() => 'Music',
      TimerActivity() => 'Timer',
      IncomingCallActivity() => 'Incoming call',
      NavigationActivity() => 'Navigation',
      WorkoutActivity() => 'Workout',
      OrderTrackingActivity() => 'Order tracking',
      BatteryActivity() => 'Battery',
      NotificationActivity() => 'Notification',
      HeyNekoActivity() => 'Hey Neko',
    };
    return 'Neko notch, $kind';
  }

  Widget _buildContent(NotchState state) {
    final NotchActivity? primary = state.primary;
    if (!state.isVisible || primary == null) {
      return const NotchIdleContent();
    }
    return switch (primary) {
      HeyNekoActivity a => HeyNekoContent(activity: a),
      IncomingCallActivity a => CallContent(activity: a),
      NavigationActivity a => NavContent(activity: a, mode: state.mode),
      TimerActivity a => TimerContent(activity: a, mode: state.mode),
      MusicActivity a => MusicContent(activity: a, mode: state.mode),
      WorkoutActivity a => WorkoutContent(activity: a, mode: state.mode),
      OrderTrackingActivity a => OrderContent(activity: a, mode: state.mode),
      BatteryActivity a => BatteryContent(activity: a),
      NotificationActivity a => NotificationContent(activity: a),
    };
  }
}

class _PillDimensions {
  const _PillDimensions({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final double radius;

  factory _PillDimensions.forState(NotchState state, double screenWidth) =>
      switch (state.mode) {
        NotchDisplayMode.idle => const _PillDimensions(
          width: 36,
          height: 36,
          radius: 18,
        ),
        NotchDisplayMode.compact => const _PillDimensions(
          width: 220,
          height: 36,
          radius: 18,
        ),
        NotchDisplayMode.expanded => _PillDimensions(
          width: screenWidth - 32,
          height: 88,
          radius: 24,
        ),
        NotchDisplayMode.heyNeko => _PillDimensions(
          width: screenWidth - 24,
          height: 108,
          radius: 30,
        ),
      };
}
