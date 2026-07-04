import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../model/notch_command.dart';
import '../notch_channels.dart';

abstract final class NotchMetrics {
  const NotchMetrics._();

  static const int idleWidth = 80;
  static const int activeWidth = 212;

  static const int idleContent = 5;
  static const int compactContent = 40;
  static const int expandedContent = 124;

  static double get devicePixelRatio =>
      ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 3.0;

  static int toPx(int dp) => (dp * devicePixelRatio).round();

  static double get statusBarInset {
    final ui.FlutterView? view = ui.PlatformDispatcher.instance.implicitView;
    final double dp = view != null ? view.padding.top / view.devicePixelRatio : 28;
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
    }
  }

  Future<void> resync() async {
    try {
      await _method.invokeMethod<void>(NotchChannels.resync);
    } on PlatformException {
    }
  }

  Future<void> mediaControl(String action) async {
    try {
      await _method.invokeMethod<void>(NotchChannels.mediaControl, <String, dynamic>{
        'action': action,
      });
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
