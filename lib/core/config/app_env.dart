/// Compile-time app configuration, injected at build time via
/// `--dart-define-from-file=.env` (or individual `--dart-define` flags):
///
/// ```sh
/// flutter run --dart-define-from-file=.env
/// flutter build apk --dart-define-from-file=.env
/// ```
///
/// This replaces flutter_dotenv, which bundled the whole `.env` file into the
/// APK as a plain-text asset — anyone could unzip the APK and read every key.
/// `String.fromEnvironment` values are compiled into the Dart snapshot instead,
/// so the raw file never ships. The `.env` file itself stays gitignored; see
/// `.env.example` for the expected keys.
abstract final class AppEnv {
  const AppEnv._();

  // ── Firebase ────────────────────────────────────────────────────────────
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String firebaseAppIdWeb = String.fromEnvironment(
    'FIREBASE_APP_ID_WEB',
  );
  static const String firebaseAppIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
  );
  static const String firebaseAppIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
  );
  static const String firebaseAppIdMacos = String.fromEnvironment(
    'FIREBASE_APP_ID_MACOS',
  );
  static const String firebaseAppIdWindows = String.fromEnvironment(
    'FIREBASE_APP_ID_WINDOWS',
  );

  /// Whether enough Firebase config was provided at build time to initialise.
  /// When false the app shows a clear "configuration missing" screen instead
  /// of crashing on startup.
  static bool get hasFirebaseConfig =>
      firebaseApiKey.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      firebaseAppIdAndroid.isNotEmpty;

  // ── Hack Club AI proxy ──────────────────────────────────────────────────
  static const String _hackclubApiKey = String.fromEnvironment(
    'HACKCLUB_API_KEY',
  );
  static const String _aiApiKey = String.fromEnvironment('AI_API_KEY');

  /// The value `.env.example` ships for HACKCLUB_API_KEY; treated the same as
  /// "no key set" everywhere so a copied-but-unfilled line can't shadow a real
  /// alternate key or reach the network.
  static const String placeholderAiKey = 'replace_with_your_hackclub_api_key';

  /// The AI bearer token. `HACKCLUB_API_KEY` wins when it's a real value;
  /// `AI_API_KEY` is the documented alternate for another OpenAI-compatible
  /// backend, so an untouched placeholder must not shadow it.
  static String get aiApiKey =>
      (_hackclubApiKey.isNotEmpty && _hackclubApiKey != placeholderAiKey)
      ? _hackclubApiKey
      : _aiApiKey;

  static const String aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'https://ai.hackclub.com/proxy/v1',
  );
  static const String aiModel = String.fromEnvironment(
    'AI_MODEL',
    defaultValue: 'google/gemini-3-flash-preview',
  );

  // ── Hack Club web search ────────────────────────────────────────────────
  static const String searchApiKey = String.fromEnvironment('SEARCH_API_KEY');
  static const String searchBaseUrl = String.fromEnvironment(
    'SEARCH_BASE_URL',
    defaultValue: 'https://search.hackclub.com',
  );
}
