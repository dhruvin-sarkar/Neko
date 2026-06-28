import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/neko_app.dart';
import 'core/neko_motion.dart';
import 'core/services/audio_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/utils/logger.dart';
import 'features/onboarding/data/onboarding_persistence.dart';
import 'features/settings/providers/sound_settings_controller.dart';
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

      try {
        await dotenv.load(fileName: '.env');
      } on Object catch (e) {
        AppLogger.warning('Could not load .env; continuing without it', e);
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // On-device media store (profile pictures + documents) and the SFX
      // engine. Both are best-effort and never block startup on failure.
      await LocalStorageService.init();
      await AudioService.init();

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      // Apply the saved mute/volume preference to the engine before first frame.
      container.read(soundSettingsControllerProvider);

      runApp(
        UncontrolledProviderScope(container: container, child: const NekoApp()),
      );
    },
    (Object error, StackTrace stack) {
      AppLogger.error('Uncaught zone error', error, stack);
    },
  );
}
