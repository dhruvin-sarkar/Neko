import 'dart:async';

import 'package:flutter/services.dart';
import 'package:live_activities/live_activities.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../utils/logger.dart';
import '../models/notch_activity.dart';
import '../models/notch_state.dart';

part 'notch_controller.g.dart';

/// The single source of truth for the Neko Notch. Drives both layers at once:
/// the in-app Flutter pill (via [NotchState]) and the system `live_activities`
/// notification.
///
/// The system layer is strictly best-effort: if `live_activities` is
/// unavailable (older Android, notification permission denied, a desktop host),
/// every call is caught and logged — the in-app pill keeps working, so the notch
/// never throws into the UI. All system calls are serialised so create/update/
/// end can never interleave.
@Riverpod(keepAlive: true)
class NotchController extends _$NotchController {
  final LiveActivities _liveActivities = LiveActivities();

  /// One reused activity id — the notch only shows one system notification (the
  /// current primary), created once and updated thereafter.
  static const String _kActivityId = 'neko_notch';

  bool _laInitialised = false;
  bool _activityCreated = false;
  bool _systemNotchWarned = false;
  bool _systemLayerDisabled = false;
  Timer? _collapseTimer;
  Timer? _heyNekoIdleTimer;
  Timer? _timerSystemTicker;

  /// Serialises every `live_activities` call so create/update/end never race.
  Future<void> _systemOps = Future<void>.value();

  @override
  NotchState build() {
    ref.onDispose(() {
      _collapseTimer?.cancel();
      _heyNekoIdleTimer?.cancel();
      _timerSystemTicker?.cancel();
      unawaited(_enqueueSystemOp(_endSystemActivity));
    });
    return NotchState.empty;
  }

  // ─── PUBLIC API ────────────────────────────────────────────────

  /// Push (or replace) an activity. A genuinely new activity grabs attention
  /// (haptic, reset expand, schedule auto-collapse); an activity of a type
  /// already shown is replaced in place without reshuffling order.
  Future<void> push(NotchActivity activity) async {
    final List<NotchActivity> updated = _merge(activity);
    final NotchActivity primary = updated.first;
    // If the pushed activity merged into a queued (non-primary) slot, don't
    // grab attention (reset expand, buzz, restart auto-collapse) for something
    // the user can't see — refresh the list + system layer quietly instead.
    final bool becamePrimary = identical(primary, activity);

    if (becamePrimary) {
      state = state.copyWith(
        mode: _modeFor(primary),
        activeActivities: updated,
        isVisible: true,
        userExpanded: false,
      );
      unawaited(_enqueueSystemOp(() => _syncSystemActivity(primary)));
      _scheduleTimerSystemResync(primary);
      _scheduleAutoCollapse(primary);
      unawaited(HapticFeedback.lightImpact());
    } else {
      state = state.copyWith(activeActivities: updated, isVisible: true);
      unawaited(_enqueueSystemOp(() => _syncSystemActivity(primary)));
    }
  }

  /// Refresh an existing activity in place (music tick, timer tick, …). Unlike
  /// [push] this does NOT buzz, reset the user's expand, reorder, or restart the
  /// auto-collapse timer — so a per-second tick can't fight the user or spam
  /// haptics. An unknown activity type falls back to a full [push].
  Future<void> update(NotchActivity activity) async {
    final int idx = state.activeActivities.indexWhere(
      (NotchActivity a) => a.runtimeType == activity.runtimeType,
    );
    if (idx == -1) return push(activity);

    final List<NotchActivity> updated =
        List<NotchActivity>.of(state.activeActivities)..[idx] = activity;
    // Priority is a per-type constant, so an in-place data swap never reorders.
    state = state.copyWith(activeActivities: updated);
    unawaited(_enqueueSystemOp(() => _syncSystemActivity(updated.first)));
  }

  /// Remove every activity of type [T]. Falls back to idle when none remain.
  Future<void> remove<T extends NotchActivity>() async {
    final List<NotchActivity> remaining = state.activeActivities
        .where((NotchActivity a) => a is! T)
        .toList();
    if (remaining.isEmpty) {
      await _clearToIdle();
      return;
    }
    state = state.copyWith(
      activeActivities: remaining,
      mode: _modeFor(remaining.first),
    );
    _scheduleTimerSystemResync(remaining.first);
    unawaited(_enqueueSystemOp(() => _syncSystemActivity(remaining.first)));
  }

  /// Tap: compact → expanded, or cycle when multiple activities are queued.
  void onTap() {
    final NotchActivity? primary = state.primary;
    if (primary == null || state.mode == NotchDisplayMode.idle) return;
    if (primary is HeyNekoActivity) return;

    if (state.mode == NotchDisplayMode.compact) {
      _cancelAutoCollapse();
      state = state.copyWith(
        mode: NotchDisplayMode.expanded,
        userExpanded: true,
      );
    } else if (state.mode == NotchDisplayMode.expanded) {
      if (state.hasMultiple) {
        _cycleNext();
      } else {
        state = state.copyWith(
          mode: NotchDisplayMode.compact,
          userExpanded: false,
        );
        _scheduleAutoCollapse(primary);
      }
    }
    unawaited(HapticFeedback.selectionClick());
  }

  /// Long-press dismisses the current activity type.
  void onLongPress() {
    if (state.primary == null) return;
    unawaited(_dismissPrimary());
    unawaited(HapticFeedback.mediumImpact());
  }

  // ─── HEY NEKO ──────────────────────────────────────────────────

  void activateHeyNeko() {
    // Cancel a pending farewell so a fresh session can't be wiped by a stale
    // idle timer from the previous one.
    _heyNekoIdleTimer?.cancel();
    unawaited(push(const HeyNekoActivity(phase: HeyNekoPhase.waking)));
  }

  void setHeyNekoPhase(
    HeyNekoPhase phase, {
    String? spokenText,
    String? response,
  }) {
    unawaited(
      push(
        HeyNekoActivity(phase: phase, spokenText: spokenText, response: response),
      ),
    );
    // The farewell auto-removal is tracked + cancellable, so any newer phase or
    // a new session cancels it before it can delete an active conversation.
    _heyNekoIdleTimer?.cancel();
    if (phase == HeyNekoPhase.idle) {
      _heyNekoIdleTimer = Timer(
        const Duration(milliseconds: 1200),
        () => unawaited(remove<HeyNekoActivity>()),
      );
    } else {
      _heyNekoIdleTimer = null;
    }
  }

  // ─── STATE HELPERS ─────────────────────────────────────────────

  List<NotchActivity> _merge(NotchActivity activity) {
    final List<NotchActivity> current = state.activeActivities.toList();
    final int existing = current.indexWhere(
      (NotchActivity a) => a.runtimeType == activity.runtimeType,
    );
    if (existing != -1) {
      // Replace in place: an update/tick or re-push must not reshuffle order
      // (which would undo a user's cycle).
      current[existing] = activity;
      return current;
    }
    return current
      ..add(activity)
      ..sort(
        (NotchActivity a, NotchActivity b) =>
            b.priority.value.compareTo(a.priority.value),
      );
  }

  Future<void> _dismissPrimary() async {
    final NotchActivity? primary = state.primary;
    if (primary == null) return;
    // Dismissing an active Hey Neko session must also cancel its pending
    // farewell auto-removal, or the stale timer later fires against whatever is
    // primary by then.
    if (primary is HeyNekoActivity) {
      _heyNekoIdleTimer?.cancel();
      _heyNekoIdleTimer = null;
    }
    final Type type = primary.runtimeType;
    final List<NotchActivity> remaining = state.activeActivities
        .where((NotchActivity a) => a.runtimeType != type)
        .toList();
    if (remaining.isEmpty) {
      await _clearToIdle();
    } else {
      state = state.copyWith(
        activeActivities: remaining,
        mode: _modeFor(remaining.first),
      );
      _scheduleTimerSystemResync(remaining.first);
      unawaited(_enqueueSystemOp(() => _syncSystemActivity(remaining.first)));
    }
  }

  void _cycleNext() {
    final NotchActivity? primary = state.primary;
    if (primary == null || !state.hasMultiple) return;
    state = state.copyWith(
      activeActivities: <NotchActivity>[...state.queued, primary],
      mode: NotchDisplayMode.expanded,
      userExpanded: true,
    );
  }

  NotchDisplayMode _modeFor(NotchActivity activity) => switch (activity) {
    HeyNekoActivity() => NotchDisplayMode.heyNeko,
    IncomingCallActivity() => NotchDisplayMode.expanded,
    _ => NotchDisplayMode.compact,
  };

  void _scheduleAutoCollapse(NotchActivity activity) {
    _cancelAutoCollapse();
    // Calls and Hey Neko stay put until acted on.
    if (activity is IncomingCallActivity || activity is HeyNekoActivity) return;

    final Duration delay = switch (activity) {
      NavigationActivity() => const Duration(seconds: 10),
      TimerActivity() => const Duration(seconds: 6),
      NotificationActivity() => const Duration(seconds: 4),
      _ => const Duration(seconds: 5),
    };

    _collapseTimer = Timer(delay, () {
      if (!state.userExpanded) {
        state = state.copyWith(mode: NotchDisplayMode.compact);
      }
    });
  }

  void _cancelAutoCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = null;
  }

  Future<void> _clearToIdle() async {
    _cancelAutoCollapse();
    _cancelTimerSystemResync();
    final List<NotchActivity> before = state.activeActivities;
    await _enqueueSystemOp(_endSystemActivity);
    // A new activity pushed during the awaited system teardown replaces the
    // list identity; don't clobber it back to idle.
    if (!identical(state.activeActivities, before)) return;
    state = state.copyWith(
      isVisible: false,
      activeActivities: const <NotchActivity>[],
      mode: NotchDisplayMode.idle,
    );
  }

  // ─── SYSTEM LAYER (live_activities) ────────────────────────────

  /// Runs [op] strictly after all previously-enqueued system ops, so create,
  /// update and end can never interleave and desync [_activityCreated].
  Future<void> _enqueueSystemOp(Future<void> Function() op) {
    final Future<void> next = _systemOps.then((_) => op());
    _systemOps = next.catchError((Object _, StackTrace _) {});
    return next;
  }

  Future<void> _ensureLaInit() async {
    if (_laInitialised) return;
    try {
      // Requesting notification permission here (on first sync) keeps the prompt
      // contextual rather than firing at cold launch.
      await _liveActivities.init(
        appGroupId: 'group.neko.notch',
        urlScheme: 'neko',
      );
      // Only mark initialised on success, so a transient failure retries.
      _laInitialised = true;
    } on Object catch (e, st) {
      AppLogger.warning('live_activities init failed; system layer off', e, st);
    }
  }

  Future<void> _syncSystemActivity(NotchActivity activity) async {
    if (_systemLayerDisabled) return;
    await _ensureLaInit();
    final Map<String, dynamic> data = activity.toLiveActivityData();
    try {
      if (!_activityCreated) {
        // createActivity returns null (no throw) when notifications are denied.
        final String? id = await _liveActivities.createActivity(
          _kActivityId,
          data,
          removeWhenAppIsKilled: true,
        );
        if (id != null) {
          _activityCreated = true;
        } else {
          // Denied/unavailable — latch off so per-second ticks stop re-hammering
          // the native channel. The in-app pill stays fully functional; warn
          // once so it's diagnosable.
          _systemLayerDisabled = true;
          if (!_systemNotchWarned) {
            _systemNotchWarned = true;
            AppLogger.warning(
              'System notch off: notification permission not granted; '
              'in-app pill still active.',
            );
          }
        }
      } else {
        await _liveActivities.updateActivity(_kActivityId, data);
      }
    } on Object catch (e, st) {
      AppLogger.warning('Live activity sync failed; pill still active', e, st);
    }
  }

  Future<void> _endSystemActivity() async {
    if (!_activityCreated) return;
    _activityCreated = false;
    try {
      await _liveActivities.endAllActivities();
    } on Object catch (e, st) {
      AppLogger.warning('Ending live activities failed', e, st);
    }
  }

  /// A running timer's system notification would otherwise freeze at its
  /// push-time countdown (the payload is snapshotted). While a [TimerActivity]
  /// is primary, re-sync the system layer once a second so Layer 2 counts down
  /// in lockstep with the in-app pill — no haptics, no auto-collapse reset.
  void _scheduleTimerSystemResync(NotchActivity activity) {
    _cancelTimerSystemResync();
    if (activity is! TimerActivity) return;
    _timerSystemTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final NotchActivity? primary = state.primary;
      if (primary is! TimerActivity) {
        _cancelTimerSystemResync();
        return;
      }
      unawaited(_enqueueSystemOp(() => _syncSystemActivity(primary)));
      if (primary.secondsLeftAt(DateTime.now()) <= 0) _cancelTimerSystemResync();
    });
  }

  void _cancelTimerSystemResync() {
    _timerSystemTicker?.cancel();
    _timerSystemTicker = null;
  }
}
