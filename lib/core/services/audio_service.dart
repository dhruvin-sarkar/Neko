import 'package:audioplayers/audioplayers.dart';

import '../utils/logger.dart';

/// Plays the app's short UI sound effects (button clicks, success, error).
///
/// One low-latency [AudioPlayer] is kept per clip and its source is preloaded
/// once in [init], so replays are instant. Everything is defensive: if a clip
/// can't load or play (missing asset, platform quirk) it's logged and skipped,
/// never thrown — sound is a nicety, never a blocker. The bundled clips are
/// silent placeholders; drop real CC0 clips into `assets/audio/` to enable
/// actual sound.
class AudioService {
  AudioService._();

  /// All effects play at this volume so the app never feels loud.
  static const double _volume = 0.35;

  static final Map<String, AudioPlayer> _players = <String, AudioPlayer>{};
  static bool _ready = false;

  // Asset paths are relative to `assets/` (audioplayers' default prefix).
  static const Map<String, String> _clips = <String, String>{
    'click': 'audio/click_primary.wav',
    'click_soft': 'audio/click_secondary.wav',
    'success': 'audio/success.wav',
    'error': 'audio/error.wav',
  };

  /// Preloads every clip. Call once from `main()` before `runApp`.
  static Future<void> init() async {
    if (_ready) return;
    try {
      for (final MapEntry<String, String> clip in _clips.entries) {
        final AudioPlayer player = AudioPlayer()
          ..setReleaseMode(ReleaseMode.stop)
          ..setPlayerMode(PlayerMode.lowLatency);
        await player.setSource(AssetSource(clip.value));
        await player.setVolume(_volume);
        _players[clip.key] = player;
      }
      _ready = true;
    } on Object catch (e, st) {
      AppLogger.warning('AudioService init failed; sounds disabled', e, st);
    }
  }

  static Future<void> _play(String key) async {
    if (!_ready) return;
    final AudioPlayer? player = _players[key];
    if (player == null) return;
    try {
      await player.seek(Duration.zero);
      await player.resume();
    } on Object {
      // Some platforms don't support seek in low-latency mode — fall back to a
      // plain replay. A failure here is harmless, so we swallow it.
      try {
        await player.play(AssetSource(_clips[key]!), volume: _volume);
      } on Object {
        // Ignore — sound is non-essential.
      }
    }
  }

  static Future<void> playClick() => _play('click');
  static Future<void> playClickSoft() => _play('click_soft');
  static Future<void> playSuccess() => _play('success');
  static Future<void> playError() => _play('error');

  /// Releases every player. Rarely needed (the service lives for the whole app)
  /// but available for completeness.
  static Future<void> dispose() async {
    for (final AudioPlayer player in _players.values) {
      await player.dispose();
    }
    _players.clear();
    _ready = false;
  }
}
