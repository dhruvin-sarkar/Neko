import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../model/notch_command.dart';
import '../notch_channels.dart';

abstract final class NotchMetrics {
  const NotchMetrics._();

  static const int idleWidth = 80;
  static const int activeWidth = 212;

  /// The design expanded width; the visual island animates across it.
  static const int _kExpandedWidth = 316;

  /// Expanded width, adapted to the device: capped to the screen minus a
  /// comfortable margin so the island never touches the edges on a narrow phone
  /// (or in landscape), while staying the design width on normal/large screens.
  static int get expandedWidth {
    final double sw = _screenWidthDp;
    // Implausibly small ⇒ we couldn't read the real screen; don't cap.
    if (sw < 280) return _kExpandedWidth;
    final int cap = (sw - 28).floor();
    return _kExpandedWidth < cap ? _kExpandedWidth : cap;
  }

  static const int idleContent = 5;
  static const int compactContent = 42;
  static const int expandedContent = 136;

  static double get devicePixelRatio =>
      ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 3.0;

  /// The device's screen width in logical pixels, taken from the physical
  /// [ui.Display] (NOT the overlay's own resized window — reading the window
  /// would feed its width back into the width calc). Returns a large sentinel
  /// when it can't be determined, so callers simply don't cap.
  static double get _screenWidthDp {
    try {
      final Iterable<ui.Display> displays =
          ui.PlatformDispatcher.instance.displays;
      if (displays.isNotEmpty) {
        final ui.Display d = displays.first;
        final double dpr = d.devicePixelRatio <= 0 ? 1.0 : d.devicePixelRatio;
        final double w = d.size.width / dpr;
        if (w > 100) return w;
      }
    } on Object {
      // Fall through to the "unknown" sentinel.
    }
    return 4096;
  }

  static int toPx(int dp) => (dp * devicePixelRatio).round();

  static double get statusBarInset {
    final ui.FlutterView? view = ui.PlatformDispatcher.instance.implicitView;
    final double dp = view != null
        ? view.padding.top / view.devicePixelRatio
        : 28;
    return dp < 20 ? 28 : dp;
  }
}

class NotchOverlayService {
  const NotchOverlayService();

  static const MethodChannel _method = MethodChannel(NotchChannels.method);

  Future<bool> hasOverlayPermission() =>
      FlutterOverlayWindow.isPermissionGranted();

  Future<bool> requestOverlayPermission() async =>
      (await FlutterOverlayWindow.requestPermission()) ?? false;

  Future<bool> isActive() => FlutterOverlayWindow.isActive();

  Future<bool> hasNotificationAccess() async {
    try {
      return await _method.invokeMethod<bool>(
            NotchChannels.hasNotificationAccess,
          ) ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> openNotificationAccessSettings() async {
    try {
      await _method.invokeMethod<void>(
        NotchChannels.openNotificationAccessSettings,
      );
    } on PlatformException {
      // Best-effort: the settings screen simply doesn't open.
    }
  }

  Future<void> resync() async {
    try {
      await _method.invokeMethod<void>(NotchChannels.resync);
    } on PlatformException {
      // Best-effort: the next native event repopulates the island anyway.
    }
  }

  Future<void> mediaControl(String action) async {
    try {
      await _method.invokeMethod<void>(
        NotchChannels.mediaControl,
        <String, dynamic>{'action': action},
      );
    } on PlatformException {
      // ignore
    }
  }

  Future<void> show({bool restart = false}) async {
    if (await FlutterOverlayWindow.isActive()) {
      if (!restart) return;
      await FlutterOverlayWindow.closeOverlay();
      // Let the cached overlay engine tear down before re-showing.
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    final int idleWindow =
        NotchMetrics.idleContent + NotchMetrics.statusBarInset.round();
    await FlutterOverlayWindow.showOverlay(
      width: NotchMetrics.toPx(NotchMetrics.idleWidth),
      height: NotchMetrics.toPx(idleWindow),
      alignment: OverlayAlignment.topCenter,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.none,
      overlayTitle: 'Neko notch',
      overlayContent: 'Live activities up top',
      enableDrag: false,
      startPosition: const OverlayPosition(0, 0),
    );
  }

  Future<void> close() => FlutterOverlayWindow.closeOverlay();
  Future<void> send(NotchCommand command) =>
      FlutterOverlayWindow.shareData(command.encode());
}
