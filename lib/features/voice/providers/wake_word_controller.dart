import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
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

/// Optional "Hey Neko" wake word — a continuous on-device `speech_to_text` loop.
///
/// Android's recogniser is **foreground-only**: it can't record once the app is
/// swiped away, and there's no way around that without a dedicated wake engine
/// (Picovoice/Vosk) in a mic foreground service. So this listens while the app
/// is open, scanning the transcript for "neko"; on a hit it bumps
/// [WakeWordState.triggerCount] (the app root opens the Hey Neko page) and hands
/// the mic to that page's command session, taking it back when the page closes.
/// It costs battery, so it's off by default and clearly labelled in Settings.
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
    if (enabled) scheduleMicrotask(_startLoop);
    return WakeWordState(enabled: enabled);
  }

  /// Turns the wake word on or off (persisted).
  Future<void> setEnabled(bool value) async {
    await ref.read(sharedPreferencesProvider).setBool(_prefKey, value);
    state = state.copyWith(enabled: value);
    if (value) {
      unawaited(_startLoop());
    } else {
      unawaited(_stopLoop());
    }
  }

  /// Suspends the wake loop while a Hey Neko session owns the mic.
  void pause() {
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
    if (_foreground) {
      if (state.enabled && !_paused) unawaited(_startLoop());
    } else if (!_paused) {
      // Only stop OUR loop when backgrounding. While paused a Hey Neko command
      // session owns the shared mic — cancelling here would kill that session.
      unawaited(_stopLoop());
    }
  }

  Future<void> _startLoop() async {
    if (!state.enabled || _paused || !_foreground || state.listening) return;
    final bool ready = await _speech.ensureReady(
      onStatus: _onStatus,
      onError: _onError,
    );
    if (!ready || !state.enabled || _paused || !_foreground) return;
    if (_speech.isListening) return;
    state = state.copyWith(listening: true);
    // Hold the mic open through long silences (the max the recogniser allows)
    // so the wake word isn't a rapid on/off cycle that flickers the mic dot.
    await _speech.listen(
      onWords: _scan,
      onFinal: (_) {},
      pauseFor: const Duration(seconds: 30),
      listenFor: const Duration(seconds: 60),
    );
  }

  Future<void> _stopLoop() async {
    if (state.listening) state = state.copyWith(listening: false);
    await _speech.cancel();
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (state.listening) state = state.copyWith(listening: false);
      // Re-arm the loop after a short breath so we don't hammer the recogniser.
      if (state.enabled && !_paused && _foreground) {
        Future<void>.delayed(const Duration(milliseconds: 450), _startLoop);
      }
    }
  }

  void _onError(String error) {
    if (state.listening) state = state.copyWith(listening: false);
    if (state.enabled && !_paused && _foreground) {
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
  }
}
