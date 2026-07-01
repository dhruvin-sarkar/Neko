import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import '../utils/logger.dart';

/// Every UI sound effect in the app, named by intent rather than by file.
///
/// Each value maps to a clip under `assets/sounds/` (see [_assets]). The set is
/// the single source of truth for "what sounds exist" — widgets reference a
/// [SoundId], never a path. [catPurrLoop] and [cottagecoreLoop] are the two
/// looping clips; drive them with the ambient/music controls, not [playSound].
enum SoundId {
  catMeowGreet,
  catMeowSuccess,
  catTrill,
  catChirp,
  catPurrLoop,
  catMeowNotif,
  btnTapPrimary,
  btnTapSoft,
  navTap,
  toggle,
  selectOption,
  correct,
  wrong,
  celebrate,
  progressTick,
  loginSuccess,
  swipeForward,
  swipeBack,
  sheetOpen,
  sheetClose,
  notchExpand,
  notchCollapse,
  notchPing,
  cameraShutter,
  uploadDone,
  saveConfirm,

  /// The continuous cottagecore background-music loop (its own volume channel).
  cottagecoreLoop,
}

/// The app's single sound engine: one low-latency [AudioPlayer] per clip,
/// preloaded once in [init] so replays are instant (`seek(0)` + `resume`).
///
/// Everything is defensive: a clip that can't load (the file isn't bundled yet,
/// a platform quirk) is logged once and simply skipped — [playSound] for it
/// becomes a no-op. Sound is a nicety, never a blocker, and a missing asset must
/// never throw or jank startup. Drop the real CC0 clips into `assets/sounds/`
/// using the filenames in [_assets] to light each one up; no code change needed.
///
/// Static by design: leaf widgets (e.g. the tactile button) fire sounds without
/// needing a Riverpod `ref`. Mute and volume are pushed in from
/// `SoundSettingsController`, which owns the persisted user preference.
class AudioService {
  AudioService._();

  /// Loudest the ambient purr may ever get.
  static const double _maxAmbient = 0.7;

  /// Loudest the background music may ever get — capped low so it stays a gentle,
  /// non-intrusive backdrop.
  static const double _maxMusic = 0.5;

  static double _sfxVolume = 1.0;
  static double _ambientVolume = 0.4;
  static bool _muted = false;

  static final Map<SoundId, AudioPlayer> _players = <SoundId, AudioPlayer>{};
  // The asset path each SoundId actually loaded from (canonical or fallback) —
  // used by the replay path in [playSound].
  static final Map<SoundId, String> _resolved = <SoundId, String>{};
  static bool _ready = false;

  // Purr state: tracked so we can fade, pause on background, and resume.
  static bool _purrPlaying = false;
  static double _purrVolume = 0;
  static Timer? _purrFade;
  static AppLifecycleListener? _lifecycle;

  // Background-music state (the continuous cottagecore loop).
  static bool _musicStarted = false;
  static double _musicVolume = 0.15;
  static double _musicCurrent = 0;
  static Timer? _musicFade;

  /// Clip filenames, relative to `assets/` (audioplayers' default prefix).
  ///
  /// The bundled clips are cat vocals plus one background-music loop. IDs
  /// without a dedicated clip reuse a sensible stand-in — the short cat chirp for
  /// UI taps/toggles, the success meow for positive moments — so every
  /// interaction is audible. Drop more clips in and point their IDs here.
  static const Map<SoundId, String> _assets = <SoundId, String>{
    // Cat vocals.
    SoundId.catMeowGreet: 'sounds/sfx_cat_meow_greet.wav',
    SoundId.catMeowSuccess: 'sounds/sfx_cat_meow_success.mp3',
    SoundId.catTrill: 'sounds/sfx_cat_trill.mp3',
    SoundId.catChirp: 'sounds/sfx_cat_chirp.mp3',
    SoundId.catPurrLoop: 'sounds/sfx_cat_purr_loop.mp3',
    SoundId.catMeowNotif: 'sounds/sfx_cat_meow_notif.mp3',
    SoundId.notchPing: 'sounds/sfx_cat_meow_notif.mp3',
    // Continuous background music.
    SoundId.cottagecoreLoop: 'sounds/freesound_community-cottagecore-17463.mp3',
    // Taps, navigation and sheet/notch UI — reuse the short cat chirp.
    SoundId.btnTapPrimary: 'sounds/sfx_cat_chirp.mp3',
    SoundId.btnTapSoft: 'sounds/sfx_cat_chirp.mp3',
    SoundId.selectOption: 'sounds/sfx_cat_chirp.mp3',
    SoundId.progressTick: 'sounds/sfx_cat_chirp.mp3',
    SoundId.cameraShutter: 'sounds/sfx_cat_chirp.mp3',
    SoundId.swipeForward: 'sounds/sfx_cat_chirp.mp3',
    SoundId.swipeBack: 'sounds/sfx_cat_chirp.mp3',
    SoundId.sheetOpen: 'sounds/sfx_cat_chirp.mp3',
    SoundId.sheetClose: 'sounds/sfx_cat_chirp.mp3',
    SoundId.notchExpand: 'sounds/sfx_cat_chirp.mp3',
    SoundId.notchCollapse: 'sounds/sfx_cat_chirp.mp3',
    SoundId.navTap: 'sounds/sfx_cat_chirp.mp3',
    SoundId.toggle: 'sounds/sfx_cat_chirp.mp3',
    SoundId.wrong: 'sounds/sfx_cat_chirp.mp3',
    // Positive feedback — reuse the success meow.
    SoundId.correct: 'sounds/sfx_cat_meow_success.mp3',
    SoundId.celebrate: 'sounds/sfx_cat_meow_success.mp3',
    SoundId.loginSuccess: 'sounds/sfx_cat_meow_success.mp3',
    SoundId.uploadDone: 'sounds/sfx_cat_meow_success.mp3',
    SoundId.saveConfirm: 'sounds/sfx_cat_meow_success.mp3',
  };

  /// Safety net for the `.wav` clip: if a device can't decode the wav, fall back
  /// to an mp3 so the sound still plays.
  static const Map<SoundId, String> _fallbackAssets = <SoundId, String>{
    SoundId.catMeowGreet: 'sounds/sfx_cat_meow_success.mp3',
  };

  /// The two clips that loop rather than firing as one-shots.
  static bool _isLoop(SoundId id) =>
      id == SoundId.catPurrLoop || id == SoundId.cottagecoreLoop;

  /// Preloads every clip that exists. Call once from `main()` before `runApp`.
  /// Each clip is loaded independently, so one missing file never aborts the
  /// rest. Safe to call more than once.
  static Future<void> init() async {
    if (_ready) return;
    for (final MapEntry<SoundId, String> clip in _assets.entries) {
      final AudioPlayer? player = await _prepare(
        clip.key,
        clip.value,
        _isLoop(clip.key),
      );
      if (player != null) _players[clip.key] = player;
    }
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycle);
    _ready = true;
  }

  /// Loads [id] from its canonical [path], falling back to [_fallbackAssets] if
  /// the canonical clip isn't bundled. Returns null (stays silent) if neither
  /// loads. Records the winning path in [_resolved].
  static Future<AudioPlayer?> _prepare(
    SoundId id,
    String path,
    bool isLoop,
  ) async {
    final List<String> candidates = <String>[
      path,
      if (_fallbackAssets[id] != null) _fallbackAssets[id]!,
    ];
    for (final String candidate in candidates) {
      final AudioPlayer player = AudioPlayer();
      try {
        await player.setReleaseMode(
          isLoop ? ReleaseMode.loop : ReleaseMode.stop,
        );
        if (!isLoop) {
          // Low latency is for one-shots; the looping clips use the default
          // media player, which loops reliably across platforms.
          await player.setPlayerMode(PlayerMode.lowLatency);
        }
        await player.setSource(AssetSource(candidate));
        await player.setVolume(isLoop ? 0.0 : _sfxVolume);
        _resolved[id] = candidate;
        return player;
      } on Object catch (e) {
        await player.dispose();
        if (candidate == candidates.last) {
          AppLogger.warning('Sound "$path" ($id) unavailable; silent', e);
        }
      }
    }
    return null;
  }

  /// Plays a one-shot effect. Fire-and-forget: callers never await it. A no-op
  /// when muted, before [init], for a missing clip, or for a looping clip.
  static Future<void> playSound(SoundId id) async {
    if (_muted || !_ready || _isLoop(id)) return;
    final AudioPlayer? player = _players[id];
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.resume();
    } on Object {
      // Some platforms reject seek in low-latency mode — fall back to a plain
      // replay from whichever asset actually loaded. Harmless if it fails.
      try {
        await player.play(
          AssetSource(_resolved[id] ?? _assets[id]!),
          volume: _sfxVolume,
        );
      } on Object {
        // Ignore — sound is non-essential.
      }
    }
  }

  // Back-compat aliases for the tactile button and onboarding steps, which call
  // these directly without a Riverpod ref.
  static Future<void> playClick() => playSound(SoundId.btnTapPrimary);
  static Future<void> playClickSoft() => playSound(SoundId.btnTapSoft);
  static Future<void> playSuccess() => playSound(SoundId.catMeowSuccess);
  static Future<void> playError() => playSound(SoundId.wrong);

  /// Fades the ambient purr in to the configured ambient volume over ~1.5s.
  /// No-op when muted, already purring, or the clip isn't bundled.
  static Future<void> startPurr() async {
    if (_muted || !_ready || _purrPlaying) return;
    final AudioPlayer? player = _players[SoundId.catPurrLoop];
    if (player == null) return;
    _purrPlaying = true;
    try {
      _purrVolume = 0;
      await player.setVolume(0);
      await player.resume();
    } on Object catch (e) {
      AppLogger.warning('Purr failed to start', e);
      _purrPlaying = false;
      return;
    }
    _fadePurr(_ambientVolume, const Duration(milliseconds: 1500));
  }

  /// Fades the purr out over ~1.5s, then pauses it.
  static Future<void> stopPurr() async {
    final AudioPlayer? player = _players[SoundId.catPurrLoop];
    if (player == null || !_purrPlaying) return;
    _fadePurr(
      0,
      const Duration(milliseconds: 1500),
      onComplete: () {
        _purrPlaying = false;
        unawaited(player.pause());
      },
    );
  }

  /// Starts the continuous background-music loop and gently fades it in to the
  /// configured (deliberately tame) volume. Call once after [init], once the
  /// saved volume has been applied. No-op if the clip isn't bundled or the loop
  /// already started; starts silent when muted so unmuting brings it up.
  static Future<void> startMusic() async {
    if (!_ready || _musicStarted) return;
    final AudioPlayer? player = _players[SoundId.cottagecoreLoop];
    if (player == null) return;
    _musicStarted = true;
    try {
      _musicCurrent = 0;
      await player.setVolume(0);
      await player.resume();
    } on Object catch (e) {
      AppLogger.warning('Background music failed to start', e);
      _musicStarted = false;
      return;
    }
    _rampMusic(_muted ? 0.0 : _musicVolume, const Duration(milliseconds: 2500));
  }

  /// Mutes or unmutes all sound. Muting fades out any active purr and ducks the
  /// background music to silence (the loop keeps running so unmute is seamless).
  static void setMuted(bool value) {
    _muted = value;
    if (value && _purrPlaying) unawaited(stopPurr());
    if (_musicStarted) {
      _rampMusic(value ? 0.0 : _musicVolume, const Duration(milliseconds: 300));
    }
  }

  /// Sets the one-shot effects volume (0.0–1.0) and applies it live.
  static void setSfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
    for (final MapEntry<SoundId, AudioPlayer> entry in _players.entries) {
      if (_isLoop(entry.key)) continue;
      unawaited(entry.value.setVolume(_sfxVolume));
    }
  }

  /// Sets the ambient purr volume (0.0–[_maxAmbient]) and eases to it if active.
  static void setAmbientVolume(double value) {
    _ambientVolume = value.clamp(0.0, _maxAmbient);
    if (_purrPlaying && !_muted) {
      _fadePurr(_ambientVolume, const Duration(milliseconds: 250));
    }
  }

  /// Sets the background-music volume (0.0–[_maxMusic]) and eases to it if the
  /// loop is playing and unmuted.
  static void setMusicVolume(double value) {
    _musicVolume = value.clamp(0.0, _maxMusic);
    if (_musicStarted && !_muted) {
      _rampMusic(_musicVolume, const Duration(milliseconds: 200));
    }
  }

  /// Steps the purr player's volume from its current level to [target] over
  /// [duration] using a timer — audioplayers has no native volume ramp.
  static void _fadePurr(
    double target,
    Duration duration, {
    VoidCallback? onComplete,
  }) {
    final AudioPlayer? player = _players[SoundId.catPurrLoop];
    if (player == null) return;
    _purrFade?.cancel();
    const int steps = 20;
    final int stepMs = (duration.inMilliseconds / steps).round().clamp(1, 1000);
    final double start = _purrVolume;
    final double delta = target - start;
    int i = 0;
    _purrFade = Timer.periodic(Duration(milliseconds: stepMs), (Timer timer) {
      i++;
      final double v = (start + delta * (i / steps)).clamp(0.0, 1.0);
      _purrVolume = v;
      unawaited(player.setVolume(v));
      if (i >= steps) {
        timer.cancel();
        _purrFade = null;
        _purrVolume = target;
        onComplete?.call();
      }
    });
  }

  /// Ramps the music player's volume from its current level to [target] over
  /// [duration] (audioplayers has no native volume ramp).
  static void _rampMusic(double target, Duration duration) {
    final AudioPlayer? player = _players[SoundId.cottagecoreLoop];
    if (player == null) return;
    _musicFade?.cancel();
    const int steps = 20;
    final int stepMs = (duration.inMilliseconds / steps).round().clamp(1, 1000);
    final double start = _musicCurrent;
    final double delta = target - start;
    int i = 0;
    _musicFade = Timer.periodic(Duration(milliseconds: stepMs), (Timer timer) {
      i++;
      final double v = (start + delta * (i / steps)).clamp(0.0, 1.0);
      _musicCurrent = v;
      unawaited(player.setVolume(v));
      if (i >= steps) {
        timer.cancel();
        _musicFade = null;
        _musicCurrent = target;
      }
    });
  }

  /// Pauses the looping clips while the app is backgrounded; resumes on return.
  static void _onLifecycle(AppLifecycleState state) {
    final bool foreground = state == AppLifecycleState.resumed;
    final AudioPlayer? purr = _players[SoundId.catPurrLoop];
    if (purr != null && _purrPlaying) {
      if (foreground) {
        if (!_muted) unawaited(purr.resume());
      } else {
        unawaited(purr.pause());
      }
    }
    // The music loop pauses/resumes with the lifecycle; its volume already
    // reflects the mute state, so no re-ducking is needed here.
    final AudioPlayer? music = _players[SoundId.cottagecoreLoop];
    if (music != null && _musicStarted) {
      if (foreground) {
        unawaited(music.resume());
      } else {
        unawaited(music.pause());
      }
    }
  }

  /// Releases every player. Rarely needed (the service lives for the whole app).
  static Future<void> dispose() async {
    _purrFade?.cancel();
    _purrFade = null;
    _musicFade?.cancel();
    _musicFade = null;
    _lifecycle?.dispose();
    _lifecycle = null;
    for (final AudioPlayer player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _ready = false;
    _purrPlaying = false;
    _musicStarted = false;
  }
}
