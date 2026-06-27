/// All route locations in one place. No raw path strings elsewhere in the app.
abstract final class Routes {
  const Routes._();

  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String chat = '/chat';

  /// Path pattern for the cat detail route (used when registering the route).
  static const String profilePattern = '/profile/:catId';

  /// Builds the concrete cat detail location for [catId].
  static String profile(String catId) => '/profile/$catId';

  /// Builds the edit location for [catId].
  static String editCat(String catId) => '/profile/$catId/edit';

  /// Whether [location] is within the authentication section.
  static bool isAuth(String location) => location.startsWith('/auth');
}
