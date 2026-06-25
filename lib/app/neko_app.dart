import 'package:flutter/material.dart';

import '../screens/create_account_screen.dart';
import '../screens/hero_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/sign_in_screen.dart';
import '../screens/welcome_back_screen.dart';
import '../services/onboarding_storage.dart';

enum AppRoute {
  hero,
  onboarding,
  createAccount,
  signIn,
  welcomeBack,
  home,
  loggedInPlaceholder,
}

class NekoApp extends StatefulWidget {
  const NekoApp({super.key});

  @override
  State<NekoApp> createState() => _NekoAppState();
}

class _NekoAppState extends State<NekoApp> {
  AppRoute _route = AppRoute.hero;
  String _catName = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    final loggedIn = await OnboardingStorage.isLoggedIn();
    final catName = await OnboardingStorage.getCatName();

    if (loggedIn && catName != null) {
      setState(() {
        _catName = catName;
        _route = AppRoute.home;
        _initialized = true;
      });
      return;
    }

    setState(() => _initialized = true);
  }

  void _navigateTo(AppRoute route) {
    setState(() => _route = route);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F0),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF28C4B)),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        final isReverse = _route == AppRoute.hero;
        final begin = isReverse
            ? const Offset(-0.08, 0)
            : const Offset(0.08, 0);
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey(_route), child: _buildScreen()),
    );
  }

  Widget _buildScreen() {
    switch (_route) {
      case AppRoute.hero:
        return HeroScreen(
          onGetStarted: () => _navigateTo(AppRoute.onboarding),
          onSignIn: () => _navigateTo(AppRoute.signIn),
        );
      case AppRoute.onboarding:
        return OnboardingScreen(
          onComplete: (name, _) {
            _catName = name;
            _navigateTo(AppRoute.createAccount);
          },
          onBack: () => _navigateTo(AppRoute.hero),
        );
      case AppRoute.createAccount:
        return CreateAccountScreen(
          catName: _catName,
          onAccountCreated: () => _navigateTo(AppRoute.loggedInPlaceholder),
          onBack: () => _navigateTo(AppRoute.onboarding),
          onSignIn: () => _navigateTo(AppRoute.signIn),
        );
      case AppRoute.signIn:
        return SignInScreen(
          onSignedIn: () => _navigateTo(AppRoute.loggedInPlaceholder),
          onGetStarted: () => _navigateTo(AppRoute.onboarding),
          onBack: _route == AppRoute.signIn
              ? () => _navigateTo(AppRoute.hero)
              : null,
        );
      case AppRoute.welcomeBack:
        return WelcomeBackScreen(
          catName: _catName,
          onComplete: () => _navigateTo(AppRoute.home),
        );
      case AppRoute.home:
        return const HomeScreen();
      case AppRoute.loggedInPlaceholder:
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Logged In',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => _navigateTo(AppRoute.home),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ),
          ),
        );
    }
  }
}
