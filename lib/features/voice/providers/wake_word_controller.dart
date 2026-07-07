import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

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

  // Whole-word tokens speech_to_text commonly emits for "Neko" — matched by
  // word, not as a substring, so they can't fire inside an unrelated word.
  static const Set<String> _nekoTokens = <String>{
    'neko', 'neco', 'necko', 'nekko', 'neeko', 'neaco', 'neku', 'neka',
    'nekoh', 'neyko', 'nekow', 'necco', 'negko', 'nemko', 'naco',
  };

  // Lead words that plausibly precede the name. A "strong" lead (an actual
  // greeting) tolerates a fuzzy neko match ("hey neck"); any lead only clears an
  // exact known mishear ("ok neko"), so a near-miss can't wake on a stray word.
  static const Set<String> _leadStrong = <String>{'hey', 'hay', 'hi'};
  static const Set<String> _leadAny = <String>{
    'hey', 'hay', 'hi', 'ok', 'okay', 'yo', 'a', 'ay', 'ey',
  };

  // Real words / names that "Neko" is often misheard as ("neck", or the name
  // "Nico") — only trusted right after a real greeting, so a bare occurrence of
  // them can never wake it.
  static const Set<String> _leadOnlyTokens = <String>{
    'neck', 'necks', 'nico', 'niko', 'nika',
  };

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

  /// Suspends the wake loop while a Hey Neko session owns the mic. Awaitable:
  /// the session awaits this so the recogniser is fully released (and its stray
  /// end-of-session status drained) before the session re-points the shared
  /// mic callbacks.
  Future<void> pause() async {
    // The session this trigger was waiting on has arrived — call off the
    // watchdog.
    _awaitingSession = false;
    _paused = true;
    await _stopLoop();
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
          // Pin English so "Neko" is heard the same way on any device locale.
          preferEnglish: true,
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
    if (matchesWake(words)) unawaited(_trigger());
  }

  /// Pure wake-word matcher over a (possibly partial) transcript. Static and
  /// side-effect-free so it can be unit-tested without a recogniser.
  static bool matchesWake(String words) {
    final List<String> toks = words
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((String t) => t.isNotEmpty)
        .toList();
    for (int i = 0; i < toks.length; i++) {
      final String t = toks[i];
      // "Neko" on its own (an exact known mishear).
      if (_nekoTokens.contains(t)) return true;
      final String? next = i + 1 < toks.length ? toks[i + 1] : null;
      if (next != null && _leadAny.contains(t)) {
        // Any lead + an exact mishear; or a real greeting + a fuzzy near-miss or
        // a known look-alike word ("hey neck", "hey nico").
        final bool strong = _leadStrong.contains(t);
        if (_nekoTokens.contains(next) ||
            (strong &&
                (_isNekoLike(next) || _leadOnlyTokens.contains(next)))) {
          return true;
        }
      }
      // The recogniser sometimes fuses them into one token ("heyneko").
      if (t.length >= 6 &&
          (t.startsWith('hey') || t.startsWith('hay')) &&
          _isNekoLike(t.substring(3))) {
        return true;
      }
    }
    return false;
  }

  /// Whether [token] is, or is one edit away from, the "Neko" sound. The fuzzy
  /// arm is only ever consulted after a strong lead word, so a near-miss like
  /// "neck" or "nero" can never wake on its own.
  static bool _isNekoLike(String token) {
    if (_nekoTokens.contains(token)) return true;
    return token.length >= 4 &&
        token.length <= 6 &&
        _editDistance(token, 'neko') <= 1;
  }

  /// Levenshtein distance. Inputs are single short words, so the plain
  /// two-row O(n*m) is more than fast enough.
  static int _editDistance(String a, String b) {
    final int n = a.length, m = b.length;
    if (n == 0) return m;
    if (m == 0) return n;
    List<int> prev = List<int>.generate(m + 1, (int j) => j);
    List<int> cur = List<int>.filled(m + 1, 0);
    for (int i = 1; i <= n; i++) {
      cur[0] = i;
      for (int j = 1; j <= m; j++) {
        final int cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        cur[j] = math.min(
          math.min(cur[j - 1] + 1, prev[j] + 1),
          prev[j - 1] + cost,
        );
      }
      final List<int> tmp = prev;
      prev = cur;
      cur = tmp;
    }
    return prev[m];
  }

  /// True between a wake trigger and the Hey Neko session claiming the mic
  /// (its page calls [pause]); the watchdog below re-arms the loop if that
  /// claim never arrives, so hands-free can't die in a paused limbo.
  bool _awaitingSession = false;

  Future<void> _trigger() async {
    // Drop stray late finals: a recogniser can deliver an in-flight result
    // across the cancel boundary. Without the _paused guard that could open a
    // second stacked session.
    if (_triggering || _paused) return;
    _triggering = true;
    _paused = true;
    await _speech.cancel();
    if (state.listening) state = state.copyWith(listening: false);
    unawaited(AudioService.playSound(SoundId.catChirp));
    // Heard while backgrounded: the app root can only show the session if the
    // window is actually in front, so bring it forward first (legal via the
    // overlay permission's background-activity-start exemption). Otherwise the
    // route would be pushed onto an invisible navigator and the user would
    // find a surprise live session on next open.
    if (!_foreground) {
      try {
        await _channel.invokeMethod<void>(NotchChannels.bringToFront);
      } on Object catch (e, st) {
        AppLogger.warning('Could not bring Neko to front for wake', e, st);
      }
    }
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
