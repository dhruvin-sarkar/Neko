import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/neko_palette.dart';
import '../model/notch_activity.dart';
import '../model/notch_command.dart';
import '../notch_channels.dart';
import '../service/notch_overlay_service.dart';
import '../service/notch_theme_mapper.dart';
import 'widgets/notch_pill.dart';

void runNotchOverlay() {
  runApp(const _NotchOverlayApp());
}

class _NotchOverlayApp extends StatelessWidget {
  const _NotchOverlayApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: const Color(0x00000000),
      // The island is glanceable system chrome, so clamp the OS font scale to a
      // narrow band: a large accessibility text size must not blow out and clip
      // the fixed-height pill, while a small one still shrinks a touch. Like
      // Apple's Dynamic Island, which stays a controlled size regardless.
      builder: (BuildContext context, Widget? child) =>
          MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.9,
            maxScaleFactor: 1.1,
            child: child ?? const SizedBox.shrink(),
          ),
      home: const NotchPill(),
    );
  }
}

Future<void> runNotchBoot() async {
  WidgetsFlutterBinding.ensureInitialized();
  const MethodChannel bootChannel = MethodChannel(NotchChannels.boot);

  try {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await bootChannel.invokeMethod<void>(NotchChannels.stopBoot);
      return;
    }

    if (!await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.showOverlay(
        width: NotchMetrics.toPx(NotchMetrics.idleWidth),
        height: NotchMetrics.toPx(
          NotchMetrics.idleContent + NotchMetrics.statusBarInset.round(),
        ),
        alignment: OverlayAlignment.topCenter,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.none,
        overlayTitle: 'Neko notch',
        overlayContent: 'Live activities up top',
        startPosition: const OverlayPosition(0, 0),
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    if (!NotchPrefs.getBool(prefs, NotchPrefs.enabled)) {
      return;
    }

    final NekoPalette palette = NekoPalettes.byId(
      prefs.getString('app_theme_palette'),
    );
    await FlutterOverlayWindow.shareData(
      NotchThemeCommand(NotchThemeMapper.fromPalette(palette)).encode(),
    );

    final String? restore = NotchPrefs.getString(prefs, NotchPrefs.restore);
    if (restore != null && restore.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(restore);
        if (decoded is List) {
          for (final Object? item in decoded) {
            if (item is Map) {
              final NotchActivity activity = NotchActivity.fromJson(
                item.cast<String, dynamic>(),
              );
              await FlutterOverlayWindow.shareData(
                PushActivityCommand(activity).encode(),
              );
            }
          }
        }
      } on FormatException {
        // ignore
      }
    }

    final String? pending = NotchPrefs.getString(prefs, NotchPrefs.pending);
    if (pending != null && pending.isNotEmpty) {
      await FlutterOverlayWindow.shareData(pending);
      await NotchPrefs.remove(prefs, NotchPrefs.pending);
    }
  } on Object {
    // Boot restore is best-effort; a failure just means no overlay until the
    // app is next opened.
  }
}
