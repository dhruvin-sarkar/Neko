import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/providers/firebase_providers.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/register_screen.dart';
import '../features/auth/ui/splash_screen.dart';
import '../features/onboarding/providers/onboarding_status_provider.dart';
import '../features/onboarding/ui/onboarding_screen.dart';
import '../features/profiles/ui/home_screen.dart';
import '../features/profiles/ui/profile_detail_screen.dart';
import '../features/settings/ui/settings_screen.dart';
import '../shared/motion/page_transitions.dart';
import 'routes.dart';
import 'splash_gate_provider.dart';

part 'router.g.dart';

/// The app router. Auth gating lives entirely in [RouterNotifier.redirect] —
/// no screen performs its own auth-based navigation.
@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  final RouterNotifier notifier = RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: <RouteBase>[
      GoRoute(
        path: Routes.splash,
        pageBuilder: (context, state) => PageTransitions.fade(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => PageTransitions.slideFromRight(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: Routes.register,
        pageBuilder: (context, state) => PageTransitions.slideFromRight(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => PageTransitions.fade(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: Routes.home,
        pageBuilder: (context, state) =>
            PageTransitions.fade(key: state.pageKey, child: const HomeScreen()),
      ),
      GoRoute(
        path: Routes.profilePattern,
        pageBuilder: (context, state) => PageTransitions.slideFromRight(
          key: state.pageKey,
          child: ProfileDetailScreen(
            catId: state.pathParameters['catId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: Routes.settings,
        pageBuilder: (context, state) => PageTransitions.slideFromRight(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
    ],
  );
}

/// Listens to auth + onboarding state and exposes the single redirect used for
/// route gating. Re-evaluates routes whenever either signal changes.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, _) => notifyListeners());
    _ref.listen(onboardingCompleteProvider, (_, _) => notifyListeners());
    _ref.listen(splashGateProvider, (_, _) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final String location = state.matchedLocation;
    final bool onSplash = location == Routes.splash;
    final bool onAuth = Routes.isAuth(location);

    // Keep the splash visible for a minimum time so it never flashes.
    if (!_ref.read(splashGateProvider)) {
      return onSplash ? null : Routes.splash;
    }

    final authValue = _ref.read(authStateChangesProvider);
    // Auth state hasn't resolved yet — hold on the splash screen.
    if (!authValue.hasValue && !authValue.hasError) {
      return onSplash ? null : Routes.splash;
    }

    final user = authValue.valueOrNull;
    if (user == null) {
      return onAuth ? null : Routes.login;
    }

    final onboardingValue = _ref.read(onboardingCompleteProvider);
    // Onboarding status not resolved yet — keep waiting on splash.
    if (!onboardingValue.hasValue && !onboardingValue.hasError) {
      return onSplash ? null : Routes.splash;
    }

    final bool complete = onboardingValue.valueOrNull ?? false;
    if (!complete) {
      return location == Routes.onboarding ? null : Routes.onboarding;
    }

    // Fully onboarded: never sit on splash or auth. The onboarding route stays
    // reachable on purpose so a returning user can add another cat.
    if (onSplash || onAuth) return Routes.home;
    return null;
  }
}
