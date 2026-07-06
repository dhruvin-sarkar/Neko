import 'package:shared_preferences/shared_preferences.dart';

abstract final class NotchChannels {
  const NotchChannels._();
  static const String method = 'neko/notch';

  static const String events = 'neko/notch_events';

  static const String boot = 'neko/notch_boot';
  static const String hasNotificationAccess = 'hasNotificationAccess';
  static const String openNotificationAccessSettings =
      'openNotificationAccessSettings';

  static const String resync = 'resyncNotch';

  static const String mediaControl = 'mediaControl';

  /// Start/stop the Hey Neko microphone foreground service (wake word).
  static const String startHeyNekoListener = 'startHeyNekoListener';
  static const String stopHeyNekoListener = 'stopHeyNekoListener';

  /// Bring MainActivity to the foreground (a background "Hey Neko" match needs
  /// the window visible before the session opens).
  static const String bringToFront = 'bringNekoToFront';

  static const String controlCommand = '__notchControl';

  static const String stopBoot = 'stop';
}

abstract final class NotchPrefs {
  const NotchPrefs._();

  static const String enabled = 'notch_enabled';

  static const String pending = 'notch_pending';

  static const String restore = 'notch_restore';

  static List<String> _candidateKeys(String key) {
    final String normalized = key.startsWith('flutter.') ? key : 'flutter.$key';
    return <String>[key, normalized];
  }

  static bool getBool(
    SharedPreferences prefs,
    String key, {
    bool defaultValue = false,
  }) {
    for (final String candidate in _candidateKeys(key)) {
      if (prefs.containsKey(candidate)) {
        return prefs.getBool(candidate) ?? defaultValue;
      }
    }
    return defaultValue;
  }

  static Future<bool> setBool(
    SharedPreferences prefs,
    String key,
    bool value,
  ) async {
    bool ok = true;
    for (final String candidate in _candidateKeys(key)) {
      ok = ok && (await prefs.setBool(candidate, value));
    }
    return ok;
  }

  static String? getString(
    SharedPreferences prefs,
    String key, {
    String? defaultValue,
  }) {
    for (final String candidate in _candidateKeys(key)) {
      if (prefs.containsKey(candidate)) {
        return prefs.getString(candidate) ?? defaultValue;
      }
    }
    return defaultValue;
  }

  static Future<bool> setString(
    SharedPreferences prefs,
    String key,
    String value,
  ) async {
    bool ok = true;
    for (final String candidate in _candidateKeys(key)) {
      ok = ok && (await prefs.setString(candidate, value));
    }
    return ok;
  }

  static Future<bool> remove(SharedPreferences prefs, String key) async {
    bool ok = true;
    for (final String candidate in _candidateKeys(key)) {
      ok = ok && (await prefs.remove(candidate));
    }
    return ok;
  }
}
