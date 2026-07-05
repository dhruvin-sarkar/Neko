import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiny sound helper for the overlay engine.
///
/// The main app's `AudioService` lives in the app engine and preloads the whole
/// clip set — far too heavy for the overlay. This keeps exactly one lazy player
/// for the island's cat noises and honours the user's saved sound preferences
/// (same SharedPreferences file, written by `SoundSettingsController`).
///
/// Everything is best-effort: if the audio plugin isn't available in this
/// engine, or a clip fails, the island must keep working silently.
abstract final class NotchSfx {
  static const String _kMutedKey = 'sound_muted';
  static const String _kSfxVolumeKey = 'sound_sfx_volume';

  static AudioPlayer? _player;

  /// A short chirp — the island noticing something (appear, expand).
  static Future<void> chirp({double scale = 1.0}) =>
      _play('sounds/sfx_cat_chirp.mp3', scale);

  /// A happy trill — a countdown finishing.
  static Future<void> trill() => _play('sounds/sfx_cat_trill.mp3', 0.9);

  static Future<void> _play(String asset, double scale) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kMutedKey) ?? false) return;
      final double volume =
          ((prefs.getDouble(_kSfxVolumeKey) ?? 1.0) * scale).clamp(0.0, 1.0);
      if (volume <= 0) return;
      final AudioPlayer player = _player ??= AudioPlayer();
      await player.stop();
      await player.play(AssetSource(asset), volume: volume);
    } on Object {
      // Sound is a nicety — the island must never break because of it.
    }
  }
}
