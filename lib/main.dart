import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/neko_app.dart';
import 'core/config/app_env.dart';
import 'core/neko_motion.dart';
import 'core/notch/overlay/notch_overlay_entry.dart';
import 'core/services/audio_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/utils/logger.dart';
import 'features/onboarding/data/onboarding_persistence.dart';
import 'features/settings/providers/sound_settings_controller.dart';
import 'features/settings/providers/theme_controller.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global motion defaults — the baseline feel for every animation.
      Animate.defaultDuration = NekoMotion.base;
      Animate.defaultCurve = NekoMotion.enter;

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'Flutter framework error',
          details.exception,
          details.stack,
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.error('Uncaught platform error', error, stack);
        return true;
      };

      // Config now arrives at compile time (--dart-define-from-file=.env), so
      // nothing secret ships inside the APK. A build made without the flag has
      // empty Firebase config — surface that clearly instead of crashing.
      if (!AppEnv.hasFirebaseConfig) {
        AppLogger.error(
          'App config missing — build with --dart-define-from-file=.env',
        );
        runApp(const _ConfigErrorApp());
        return;
      }

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on Object catch (e, st) {
        // Missing/invalid config: show a clear message instead of crashing the
        // zone on a clean install.
        AppLogger.error('Firebase failed to initialise', e, st);
        runApp(const _ConfigErrorApp());
        return;
      }

      // Edge-to-edge so Flutter draws into the status-bar zone where the Neko
      // Notch pill lives. The transparent bars + palette-aware icon brightness
      // are owned by ThemeController (applied on first build below and on every
      // theme change), so dark themes get light icons and light ones dark icons.
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Portrait-only: every screen (onboarding, home, the AI panel) and the
      // notch pill are designed for portrait; a landscape rotation would break
      // those fixed layouts and float the notch off the top cutout.
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // On-device media store (profile pictures + documents) and the SFX
      // engine. Both are best-effort and must never block startup on failure.
      try {
        await LocalStorageService.init();
      } on Object catch (e, st) {
        AppLogger.warning(
          'LocalStorageService init failed; media disabled',
          e,
          st,
        );
      }
      try {
        await AudioService.init();
      } on Object catch (e, st) {
        AppLogger.warning('AudioService init failed; sounds disabled', e, st);
      }

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      // Apply saved sound + coat-theme preferences before the first frame, so
      // the app opens muted/at-volume and in the user's chosen theme.
      container.read(soundSettingsControllerProvider);
      container.read(themeControllerProvider);
      // Kick off the continuous cottagecore background music (gentle fade-in;
      // stays silent if the user has muted). Fire-and-forget — never blocks.
      unawaited(AudioService.startMusic());

      runApp(
        UncontrolledProviderScope(container: container, child: const NekoApp()),
      );
    },
    (Object error, StackTrace stack) {
      AppLogger.error('Uncaught zone error', error, stack);
    },
  );
}

/// Entry point for the notch overlay's separate Flutter engine.
/// `flutter_overlay_window` launches the top-level function named `overlayMain`
/// in the overlay isolate; it must stay in the default entrypoint library and
/// be kept by the tree-shaker via the pragma.
@pragma('vm:entry-point')
void overlayMain() => runNotchOverlay();

/// Entry point for the tiny Flutter engine the native boot service starts after
/// a reboot; it re-shows the overlay from persisted state, then stops itself.
@pragma('vm:entry-point')
void notchBootMain() {
  unawaited(runNotchBoot());
}

/// A minimal fallback shown when the app can't initialise its backend (e.g. a
/// missing `.env` / Firebase config) — clearer than an opaque startup crash.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Neko can’t start because its configuration is missing.\n\n'
              'Build the app with --dart-define-from-file=.env '
              '(see .env.example) and relaunch.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
