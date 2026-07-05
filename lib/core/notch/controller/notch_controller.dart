import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../features/onboarding/data/onboarding_persistence.dart';
import '../../services/audio_service.dart';
import '../../utils/logger.dart';
import '../model/notch_activity.dart';
import '../model/notch_command.dart';
import '../notch_channels.dart';
import '../service/notch_overlay_service.dart';
import '../service/notch_theme_mapper.dart';

class NotchState {
  const NotchState({
    required this.enabled,
    required this.hasNotificationAccess,
    this.activeTimer,
  });

  final bool enabled;
  final bool hasNotificationAccess;

  /// The running feeding countdown, if any — lets in-app UI (the profile
  /// card) mirror what the island is showing.
  final NotchActivity? activeTimer;

  const NotchState.initial()
    : enabled = false,
      hasNotificationAccess = false,
      activeTimer = null;

  NotchState copyWith({
    bool? enabled,
    bool? hasNotificationAccess,
    NotchActivity? activeTimer,
    bool clearTimer = false,
  }) {
    return NotchState(
      enabled: enabled ?? this.enabled,
      hasNotificationAccess:
          hasNotificationAccess ?? this.hasNotificationAccess,
      activeTimer: clearTimer ? null : (activeTimer ?? this.activeTimer),
    );
  }
}

/// The on/off preference

final notchControllerProvider = NotifierProvider<NotchController, NotchState>(
  NotchController.new,
);

class NotchController extends Notifier<NotchState> {
  final NotchOverlayService _service = const NotchOverlayService();

  /// The id of the app's own feeding countdown. System/Clock timers are also
  /// `timer`-typed but carry their notification key as id, so feeding-timer
  /// bookkeeping (activeTimer, the end-of-timer meow, cancel) keys off this id
  /// and never touches a mirrored system timer.
  static const String _feedingTimerId = 'feeding_timer';

  final Map<String, NotchActivity> _ongoing = <String, NotchActivity>{};

  StreamSubscription<dynamic>? _eventsSub;

  StreamSubscription<dynamic>? _overlaySub;

  Timer? _timerEnd;

  String? _lastSyncedThemeId;

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  NotchState build() {
    final bool enabled = _prefs.getBool(NotchPrefs.enabled) ?? false;

    const EventChannel channel = EventChannel(NotchChannels.events);
    _eventsSub = channel.receiveBroadcastStream().listen(
      _onNativeEvent,
      onError: (Object e, StackTrace st) =>
          AppLogger.warning('Notch event stream error', e, st),
    );

    _overlaySub = FlutterOverlayWindow.overlayListener.listen(
      _onOverlayMessage,
    );

    ref.onDispose(() {
      _eventsSub?.cancel();
      _overlaySub?.cancel();
      _timerEnd?.cancel();
    });

    if (enabled) {
      unawaited(_ensureShown());
    }
    return NotchState(enabled: enabled, hasNotificationAccess: false);
  }

  bool get isEnabled => state.enabled;

  Future<void> setEnabled(bool value) async {
    if (value) {
      if (!await _service.hasOverlayPermission()) {
        final bool granted = await _service.requestOverlayPermission();
        if (!granted) {
          state = state.copyWith(enabled: false);
          return;
        }
      }
      await _prefs.setBool(NotchPrefs.enabled, true);
      state = state.copyWith(enabled: true);
      // Android 13+ gates the notch's foreground-service tray notification behind
      // the runtime notification permission. Best-effort + non-blocking — the
      // island still shows via SYSTEM_ALERT_WINDOW if it's denied, and
      // permission_handler auto-grants on Android < 13.
      if (Platform.isAndroid) {
        await Permission.notification.request();
      }
      await _service.show(restart: true);
      await syncTheme(force: true);
      // Drop any activities left in the cached overlay engine (e.g. the Android
      // System "displaying over other apps" nag) before we resync live state.
      await _emit(const ClearCommand());

      final bool access = await _service.hasNotificationAccess();
      state = state.copyWith(hasNotificationAccess: access);
      if (!access) {
        await _service.openNotificationAccessSettings();
      } else {
        // Playing/in progress right now so it shows
        await _service.resync();
      }

      unawaited(_showWelcome());
    } else {
      await _prefs.setBool(NotchPrefs.enabled, false);
      state = state.copyWith(enabled: false);
      _ongoing.clear();
      await _prefs.remove(NotchPrefs.restore);
      await _emit(const ClearCommand());
      await _service.close();
    }
  }

  Future<void> syncTheme({bool force = false}) async {
    if (!state.enabled) return;
    final String id = AppColors.palette.id;

    if (!force && id == _lastSyncedThemeId) return;
    _lastSyncedThemeId = id;
    await _service.send(
      NotchThemeCommand(
        NotchThemeMapper.fromPalette(
          AppColors.palette,
          topInset: _statusBarDp(),
        ),
      ),
    );
  }

  double _statusBarDp() {
    final ui.FlutterView? view = ui.PlatformDispatcher.instance.implicitView;
    if (view == null) return 28;
    final double dp = view.padding.top / view.devicePixelRatio;
    return dp < 20 ? 28 : dp;
  }

  Future<void> showActivity(NotchActivity activity) async {
    if (activity.isOngoing) {
      _ongoing[activity.key] = activity;
      await _persistRestore();
    }
    await _emit(PushActivityCommand(activity));
  }

  Future<void> updateActivity(NotchActivity activity) async {
    if (activity.isOngoing) {
      final NotchActivity? existing = _ongoing[activity.key];
      _ongoing[activity.key] = existing == null
          ? activity
          : existing.mergedWith(activity);
      await _persistRestore();
    }
    await _emit(UpdateActivityCommand(activity));
  }

  Future<void> removeActivity({String? id, NotchActivityType? type}) async {
    _ongoing.removeWhere((String key, NotchActivity a) {
      final bool byId = id != null && id.isNotEmpty && a.id == id;
      final bool byType = type != null && a.type == type;
      return byId || byType;
    });
    await _persistRestore();
    await _emit(RemoveActivityCommand(id: id, type: type));
  }

  Future<void> _showWelcome() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await showActivity(
      const NotchActivity(
        type: NotchActivityType.generic,
        id: 'welcome',
        title: 'Neko’s got your notch 🐾',
        subtitle: 'Music, calls, timers and Hey Neko live up here now',
        ongoing: false,
      ),
    );
  }

  // ── Feeding timer ──────────────────────────────────────────────────────────

  /// Starts (or restarts) the feeding countdown on the island. One at a time —
  /// starting a new one replaces the old.
  Future<void> startTimer({
    required String label,
    required Duration duration,
  }) async {
    final DateTime endsAt = DateTime.now().add(duration);
    final NotchActivity activity = NotchActivity(
      type: NotchActivityType.timer,
      id: _feedingTimerId,
      title: label,
      durationMs: duration.inMilliseconds,
      endsAtMs: endsAt.millisecondsSinceEpoch,
      ongoing: true,
    );
    state = state.copyWith(activeTimer: activity);
    _armTimerEnd(activity);
    await showActivity(activity);
  }

  /// Cancels a running feeding countdown everywhere.
  Future<void> cancelTimer() async {
    _timerEnd?.cancel();
    _timerEnd = null;
    state = state.copyWith(clearTimer: true);
    // Remove by id, not by type — a mirrored system Clock timer is also
    // `timer`-typed and must be left alone.
    await removeActivity(id: _feedingTimerId);
  }

  /// Schedules the app-engine side of a countdown finishing: a celebratory
  /// meow (the island trills for itself) and cleanup. The overlay self-removes
  /// its copy too, so this also just keeps `_ongoing`/restore state honest.
  void _armTimerEnd(NotchActivity activity) {
    _timerEnd?.cancel();
    final Duration left = DateTime.fromMillisecondsSinceEpoch(
      activity.endsAtMs ?? 0,
    ).difference(DateTime.now());
    _timerEnd = Timer(left.isNegative ? Duration.zero : left, () {
      _timerEnd = null;
      state = state.copyWith(clearTimer: true);
      // The overlay engine owns the visible completion: it holds 00:00 for a
      // beat, plays the celebratory trill, and removes its own pill. Emitting a
      // remove here would cut that grace short and a second sound would play.
      // So we only clear local bookkeeping — and when the notch is off (there's
      // no island to trill) we give an in-app meow so the countdown still lands.
      _ongoing.remove(activity.key);
      unawaited(_persistRestore());
      if (!state.enabled) {
        unawaited(AudioService.playSound(SoundId.catMeowSuccess));
      }
    });
  }

  //clear
  Future<void> clear() async {
    _ongoing.clear();
    await _persistRestore();
    await _emit(const ClearCommand());
  }

  void _onOverlayMessage(Object? raw) {
    if (raw is! String) return;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final Map<String, dynamic> map = decoded.cast<String, dynamic>();
      if (map['cmd'] != NotchChannels.controlCommand) return;
      final String action = (map['action'] ?? '').toString();
      if (action.isNotEmpty) unawaited(_service.mediaControl(action));
    } on FormatException {
      //ignore
    }
  }

  // ── Native bridge ──────────────────────────────────────────────────────────

  void _onNativeEvent(Object? raw) {
    if (raw is! Map) return;
    final Map<String, dynamic> event = raw.cast<String, dynamic>();
    switch (event['kind']) {
      case 'notification':
        unawaited(_onNotificationEvent(event));
      case 'notificationRemoved':
        final String key = (event['key'] ?? '').toString();
        _ongoing.removeWhere((_, NotchActivity a) => a.id == key);
        unawaited(_persistRestore());
        unawaited(_emit(RemoveActivityCommand(id: key)));
      case 'media':
        unawaited(_onMediaEvent(event));
      case 'mediaStopped':
        unawaited(removeActivity(type: NotchActivityType.music));
    }
  }

  Future<void> _onNotificationEvent(Map<String, dynamic> event) async {
    final String title = (event['title'] ?? '').toString();
    final String packageLabel = (event['package'] ?? '').toString();
    if (_isSystemOverlayNotification(packageLabel, title)) return;

    final String category = (event['category'] ?? '').toString();
    final bool ongoingFlag = event['ongoing'] == true;
    final double? prog = (event['progress'] as num?)?.toDouble();
    final bool hasProgress = prog != null && prog >= 0;
    final int endsAtMs = (event['endsAtMs'] as num?)?.toInt() ?? 0;

    final NotchActivityType type = switch (category) {
      'call' => NotchActivityType.call,
      'navigation' => NotchActivityType.navigation,
      'timer' => NotchActivityType.timer,
      _ when hasProgress && ongoingFlag => NotchActivityType.download,
      _ => NotchActivityType.notification,
    };
    final bool ongoing = ongoingFlag || type != NotchActivityType.notification;

    final String rawPkg = (event['packageId'] ?? '').toString();
    final NotchActivity activity = NotchActivity(
      type: type,
      id: (event['key'] ?? '').toString(),
      title: (event['title'] ?? '').toString(),
      subtitle: (event['body'] ?? '').toString(),
      appName: (event['package'] ?? '').toString(),
      packageId: rawPkg.isEmpty ? null : rawPkg,
      progress: hasProgress ? prog : null,
      endsAtMs: type == NotchActivityType.timer && endsAtMs > 0
          ? endsAtMs
          : null,
      source: 'system',
      ongoing: ongoing,
    );

    if (ongoing) {
      final NotchActivity? existing = _ongoing[activity.key];
      _ongoing[activity.key] = activity;
      await _persistRestore();
      await _emit(
        existing == null
            ? PushActivityCommand(activity)
            : UpdateActivityCommand(activity),
      );
    } else {
      await _emit(PushActivityCommand(activity));
    }
  }

  bool _isSystemOverlayNotification(String packageLabel, String title) {
    final String pkg = packageLabel.toLowerCase();
    if (pkg == 'android system' || pkg == 'system ui') return true;
    final String lower = title.toLowerCase();
    return lower.contains('displaying over') ||
        lower.contains('draw over') ||
        lower.contains('display over');
  }

  Future<void> _onMediaEvent(Map<String, dynamic> event) async {
    final int durMs = (event['duration'] as num?)?.toInt() ?? 0;
    final int posMs = (event['position'] as num?)?.toInt() ?? 0;
    final String rawPkg = (event['packageId'] ?? '').toString();
    final NotchActivity music = NotchActivity(
      type: NotchActivityType.music,
      id: 'music',
      title: (event['title'] ?? '').toString(),
      subtitle: (event['artist'] ?? '').toString(),
      packageId: rawPkg.isEmpty ? null : rawPkg,
      isPlaying: event['playing'] == true,
      progress: durMs > 0 ? (posMs / durMs).clamp(0.0, 1.0) : null,
      durationMs: durMs > 0 ? durMs : null,
      source: 'system',
      albumArt: (event['art'] as Object?)?.toString(),
    );
    final bool existed = _ongoing.containsKey(music.key);
    _ongoing[music.key] = music;
    await _persistRestore();
    await _emit(
      existed ? UpdateActivityCommand(music) : PushActivityCommand(music),
    );
  }

  Future<void> _emit(NotchCommand command) async {
    if (!state.enabled) return;
    try {
      await _service.send(command);
    } on PlatformException catch (e, st) {
      AppLogger.warning('Failed to send notch command', e, st);
    }
  }

  Future<void> _ensureShown() async {
    try {
      if (await _service.hasOverlayPermission() && !await _service.isActive()) {
        await _service.show();
      }
      await syncTheme(force: true);

      await _service.resync();
      final String? restore = _prefs.getString(NotchPrefs.restore);
      if (restore != null && restore.isNotEmpty) {
        final Object? decoded = jsonDecode(restore);
        bool dropped = false;
        if (decoded is List) {
          for (final Object? item in decoded) {
            if (item is Map) {
              final NotchActivity a = NotchActivity.fromJson(
                item.cast<String, dynamic>(),
              );
              // A countdown that ran out while we were away is gone, not
              // restored-then-instantly-removed.
              final bool expired =
                  a.type == NotchActivityType.timer &&
                  a.endsAtMs != null &&
                  a.endsAtMs! <= DateTime.now().millisecondsSinceEpoch;
              if (expired) {
                dropped = true;
                continue;
              }
              _ongoing[a.key] = a;
              if (a.id == _feedingTimerId) {
                // Re-adopt only the app's own feeding countdown so the in-app
                // card and the end-of-timer meow keep working after a restart;
                // a mirrored system timer is not ours to own.
                state = state.copyWith(activeTimer: a);
                _armTimerEnd(a);
              }
              await _emit(PushActivityCommand(a));
            }
          }
        }
        // Keep the persisted payload honest so the boot receiver doesn't
        // relaunch the overlay for something that no longer exists.
        if (dropped) await _persistRestore();
      }
    } on Object catch (e, st) {
      AppLogger.warning('Failed to restore notch on start', e, st);
    }
  }

  Future<void> _persistRestore() async {
    final List<Map<String, dynamic>> list = _ongoing.values
        .where((NotchActivity a) => a.isRestorable)
        .map((NotchActivity a) => a.toJson())
        .toList(growable: false);
    if (list.isEmpty) {
      await _prefs.remove(NotchPrefs.restore);
      return;
    }
    await _prefs.setString(NotchPrefs.restore, jsonEncode(list));
  }
}
