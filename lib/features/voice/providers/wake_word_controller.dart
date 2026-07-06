import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/notch/controller/notch_controller.dart';
import '../../../core/notch/notch_channels.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/utils/logger.dart';
import '../../onboarding/data/onboarding_persistence.dart';
import '../data/speech_service.dart';

/// Immutable snapshot of the "Hey Neko" wake-word listener.
@immutable
class WakeWordState {
  const WakeWordState({
    this.enabled = false,
    this.listening = false,
    this.triggerCount = 0,
  });

  /// The user's toggle (persisted).
  final bool enabled;

  /// Whether the wake loop is actively holding the mic right now.
  final bool listening;

  /// Increments each time "Hey Neko" is heard. A listener in the app root
  /// watches this and opens the dedicated Hey Neko page — keeping navigation
  /// out of this controller so it needn't depend on the router.
  final int triggerCount;

  WakeWordState copyWith({bool? enabled, bool? listening, int? triggerCount}) {
    return WakeWordState(
      enabled: enabled ?? this.enabled,
      listening: listening ?? this.listening,
      triggerCount: triggerCount ?? this.triggerCount,
    );
  }
}

final wakeWordControllerProvider =
    NotifierProvider<WakeWordController, WakeWordState>(WakeWordController.new);

/// Optional "Hey Neko" wake word — a continuous on-device `speech_to_text`
/// loop, scanning partial transcripts for "neko"; on a hit it bumps
/// [WakeWordState.triggerCount] (the app root opens the Hey Neko page) and
/// hands the mic to that page's command session, taking it back when the page
/// closes.
///
/// While enabled, a microphone foreground service ([NotchChannels] →
/// HeyNekoListenerService) holds the mic grant so listening continues when the
/// app moves to the background. Android forbids starting that service FROM the
/// background, so it is only ever started here from foreground moments: the
/// Settings toggle, app launch, and app resume.
///
/// The whole feature is gated behind the Neko notch master toggle (no notch →
/// no listener), costs battery, and is **off by default** — the user opts in
/// from Settings, and the service's persistent notification is honest about
/// the open mic.
class WakeWordController extends Notifier<WakeWordState> {
  static const String _prefKey = 'hey_neko_wake_enabled';

  // Words STT commonly hears for "Neko" — kept loose so the wake still fires
  // when recognition mangles the vowel.
  static const List<String> _cues = <String>[
    'hey neko',
    'hey nico',
    'hey niko',
    'neko',
    'neco',
    'nico',
    'niko',
    'necko',
  ];

  AppLifecycleListener? _lifecycle;
  bool _foreground = true;
  bool _paused = false;
  bool _triggering = false;

  SpeechService get _speech => ref.read(speechServiceProvider);

  @override
  WakeWordState build() {
    final bool enabled =
        ref.read(sharedPreferencesProvider).getBool(_prefKey) ?? false;
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    ref.onDispose(() {
      _lifecycle?.dispose();
      unawaited(_speech.cancel());
    });
    // Master gate, ongoing: switching the notch off takes the wake word (and
    // its mic service) down with it — the mic never stays hot for a feature
    // whose surface is gone.
    ref.listen(notchControllerProvider.select((s) => s.enabled), (
      bool? prev,
      bool next,
    ) {
      if (prev == true && !next && state.enabled) {
        unawaited(setEnabled(false));
      }
    });
    // Privacy: sign-out takes the mic down with it. Sign-out always happens
    // from a foreground moment (Settings), so stopping the service here is
    // legal — and the wake word stays a per-account opt-in.
    ref.listen<String?>(
      authStateChangesProvider.select((v) => v.valueOrNull?.uid),
      (String? prev, String? next) {
        if (prev != null && next == null && state.enabled) {
          unawaited(setEnabled(false));
        }
      },
    );
    if (enabled) {
      // App launch is a foreground moment — legal to (re)start the mic service.
      scheduleMicrotask(() async {
        if (!ref.read(notchControllerProvider).enabled) {
          await setEnabled(false);
          return;
        }
        // The mic permission can be revoked in system settings between
        // launches; starting a microphone-typed service without it crashes on
        // Android 14+, so re-check before touching the service — and treat a
        // recogniser that can't start as authoritative: the toggle switches
        // off rather than leaving a "listening" notification with a dead mic.
        if (Platform.isAndroid && !await Permission.microphone.isGranted) {
          await setEnabled(false);
          return;
        }
        await _startService();
        if (!await _startLoop()) await setEnabled(false);
      });
    }
    return WakeWordState(enabled: enabled);
  }

  /// Turns the wake word on or off (persisted). Enabling requires the notch
  /// master toggle on and the mic permission granted — otherwise the state
  /// stays off and the Settings card explains why.
  Future<void> setEnabled(bool value) async {
    if (value) {
      // Master gate: the wake word is a notch feature — no notch, no listener.
      if (!ref.read(notchControllerProvider).enabled) return;
      // Permissions first, from this foreground context: the tray notification
      // the mic service must show (best-effort), then the mic itself —
      // `ensureReady` drives the RECORD_AUDIO prompt. Declining the mic keeps
      // the toggle off.
      if (Platform.isAndroid) {
        await Permission.notification.request();
      }
      final bool ready = await _speech.ensureReady(
        onStatus: _onStatus,
        onError: _onError,
      );
      if (!ready) return;
      await ref.read(sharedPreferencesProvider).setBool(_prefKey, true);
      state = state.copyWith(enabled: true);
      await _startService();
      unawaited(_startLoop());
    } else {
      await ref.read(sharedPreferencesProvider).setBool(_prefKey, false);
      state = state.copyWith(enabled: false);
      await _stopService();
      unawaited(_stopLoop());
    }
  }

  // ── Mic foreground service ─────────────────────────────────────────────────

  static const MethodChannel _channel = MethodChannel(NotchChannels.method);

  /// Starts HeyNekoListenerService (idempotent). Only called from foreground
  /// moments — Android rejects a background start of a microphone service.
  Future<void> _startService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(NotchChannels.startHeyNekoListener);
    } on Object catch (e, st) {
      // Listening still works while the app is foreground; only the
      // keep-alive-in-background grant is missing. Next resume retries.
      AppLogger.warning('Hey Neko mic service start failed', e, st);
    }
  }

  Future<void> _stopService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(NotchChannels.stopHeyNekoListener);
    } on Object catch (e, st) {
      AppLogger.warning('Hey Neko mic service stop failed', e, st);
    }
  }

  /// Suspends the wake loop while a Hey Neko session owns the mic.
  void pause() {
    // The session this trigger was waiting on has arrived — call off the
    // watchdog.
    _awaitingSession = false;
    _paused = true;
    unawaited(_stopLoop());
  }

  /// Resumes listening after a Hey Neko session ends.
  void resume() {
    _paused = false;
    if (state.enabled) unawaited(_startLoop());
  }

  void _onLifecycle(AppLifecycleState s) {
    _foreground = s == AppLifecycleState.resumed;
    if (_foreground && state.enabled && !_paused) {
      // Resume is a foreground moment: re-arm the (idempotent) mic service in
      // case the system reclaimed it, and kick the loop if the recogniser
      // died. Same authoritative failure handling as launch: a mic that can't
      // start switches the feature off instead of leaving a deaf notification.
      unawaited(() async {
        if (Platform.isAndroid && !await Permission.microphone.isGranted) {
          await setEnabled(false);
          return;
        }
        await _startService();
        if (!await _startLoop()) await setEnabled(false);
      }());
    }
    // Backgrounding keeps listening — that's the mic foreground service's whole
    // job. The loop only stops when the toggle goes off or a session pauses it.
  }

  /// Guards against overlapping starts: resume, the 450ms/900ms re-arms, and a
  /// toggle can all race into here; only one may reach `listen()`.
  bool _startingLoop = false;

  /// Returns false only when the recogniser is unavailable (mic revoked,
  /// plugin dead) — launch/resume treat that as authoritative and switch the
  /// feature off. Benign early-outs (paused, already listening) return true.
  Future<bool> _startLoop() async {
    if (_startingLoop) return true;
    if (!state.enabled || _paused || state.listening) return true;
    _startingLoop = true;
    try {
      final bool ready = await _speech.ensureReady(
        onStatus: _onStatus,
        onError: _onError,
      );
      if (!ready) return false;
      if (!state.enabled || _paused || _speech.isListening) return true;
      state = state.copyWith(listening: true);
      // Hold the mic open through long silences (the max the recogniser
      // allows) so the wake word isn't a rapid on/off cycle that flickers the
      // mic dot. A throw here must not kill the loop — route it into the same
      // re-arm path a reported error takes.
      try {
        await _speech.listen(
          onWords: _scan,
          onFinal: (_) {},
          pauseFor: const Duration(seconds: 30),
          listenFor: const Duration(seconds: 60),
        );
      } on Object catch (e, st) {
        AppLogger.warning('Wake listen failed; re-arming', e, st);
        if (state.listening) state = state.copyWith(listening: false);
        _onError('listen-failed');
      }
      return true;
    } finally {
      _startingLoop = false;
    }
  }

  Future<void> _stopLoop() async {
    if (state.listening) state = state.copyWith(listening: false);
    await _speech.cancel();
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (state.listening) state = state.copyWith(listening: false);
      // Re-arm the loop after a short breath so we don't hammer the recogniser.
      // No foreground gate: the mic service keeps background listening legal.
      if (state.enabled && !_paused) {
        Future<void>.delayed(const Duration(milliseconds: 450), _startLoop);
      }
    }
  }

  void _onError(String error) {
    if (state.listening) state = state.copyWith(listening: false);
    if (state.enabled && !_paused) {
      Future<void>.delayed(const Duration(milliseconds: 900), _startLoop);
    }
  }

  void _scan(String words) {
    final String w = words.toLowerCase();
    for (final String cue in _cues) {
      if (w.contains(cue)) {
        unawaited(_trigger());
        return;
      }
    }
  }

  /// True between a wake trigger and the Hey Neko session claiming the mic
  /// (its page calls [pause]); the watchdog below re-arms the loop if that
  /// claim never arrives, so hands-free can't die in a paused limbo.
  bool _awaitingSession = false;

  Future<void> _trigger() async {
    if (_triggering) return;
    _triggering = true;
    _paused = true;
    await _speech.cancel();
    if (state.listening) state = state.copyWith(listening: false);
    unawaited(AudioService.playSound(SoundId.catChirp));
    // Bump the trigger; the app root listens and opens the Hey Neko page.
    state = state.copyWith(triggerCount: state.triggerCount + 1);
    _triggering = false;
    // Watchdog: the page normally claims the mic within a breath. If it never
    // does (session failed to spin up, route blocked), resume listening rather
    // than leaving neither the wake loop nor a session holding the mic.
    _awaitingSession = true;
    Future<void>.delayed(const Duration(seconds: 10), () {
      if (_awaitingSession && state.enabled && _paused) {
        _awaitingSession = false;
        resume();
      }
    });
  }
}
