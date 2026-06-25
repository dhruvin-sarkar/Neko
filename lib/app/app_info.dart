/// Static app metadata shown in the UI (e.g. the Settings "About" section).
///
/// Keep [version] in sync with the `version:` field in `pubspec.yaml`.
abstract final class AppInfo {
  const AppInfo._();

  static const String name = 'Neko';
  static const String version = '1.0.0';
  static const String tagline = "Your cat's new best friend.";
}
