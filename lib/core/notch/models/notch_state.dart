import 'notch_activity.dart';

/// How the pill is currently presented. Sizes are logical dp, tuned for the
/// Pixel 8 status-bar zone (see `_PillDimensions`).
enum NotchDisplayMode {
  /// ~36×36 — barely bigger than the punch-hole. Shows the cat-ear silhouette.
  idle,

  /// ~220×36 — one-line pill: icon + label.
  compact,

  /// Full-width rich card.
  expanded,

  /// Full-width cat animation for the Hey Neko assistant.
  heyNeko,
}

/// Immutable snapshot of the notch. Activities are kept sorted by priority
/// (highest first), so [primary] is always the one on show.
class NotchState {
  const NotchState({
    required this.mode,
    required this.activeActivities,
    required this.isVisible,
    required this.userExpanded,
  });

  final NotchDisplayMode mode;
  final List<NotchActivity> activeActivities;
  final bool isVisible;
  final bool userExpanded;

  NotchActivity? get primary =>
      activeActivities.isEmpty ? null : activeActivities.first;

  List<NotchActivity> get queued =>
      activeActivities.length > 1 ? activeActivities.sublist(1) : const [];

  bool get hasMultiple => activeActivities.length > 1;

  static const NotchState empty = NotchState(
    mode: NotchDisplayMode.idle,
    activeActivities: <NotchActivity>[],
    isVisible: false,
    userExpanded: false,
  );

  NotchState copyWith({
    NotchDisplayMode? mode,
    List<NotchActivity>? activeActivities,
    bool? isVisible,
    bool? userExpanded,
  }) => NotchState(
    mode: mode ?? this.mode,
    activeActivities: activeActivities ?? this.activeActivities,
    isVisible: isVisible ?? this.isVisible,
    userExpanded: userExpanded ?? this.userExpanded,
  );
}
