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
import 'core/utils/logger.dart';
import 'features/onboarding/data/onboarding_persistence.dart';
import 'firebase_options.dart';
import 'shared/services/sound_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Global motion defaults — the baseline feel for every animation.
      Animate.defaultDuration = const Duration(milliseconds: 250);
      Animate.defaultCurve = Curves.easeOutCubic;

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

      // Pre-load UI sounds so the first tap is low-latency. The same container
      // backs the app, so the initialized service is the one widgets use.
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      await container.read(soundServiceProvider).init();

      runApp(
        UncontrolledProviderScope(container: container, child: const NekoApp()),
      );
    },
    (Object error, StackTrace stack) {
      AppLogger.error('Uncaught zone error', error, stack);
    },
  );
}
