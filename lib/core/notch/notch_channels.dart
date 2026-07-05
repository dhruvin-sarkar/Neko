abstract final class NotchChannels {
  const NotchChannels._();
  static const String method = 'neko/notch';

  static const String events = 'neko/notch_events';

  static const String boot = 'neko/notch_boot';
  static const String hasNotificationAccess = 'hasNotificationAccess';
  static const String openNotificationAccessSettings =
      'openNotificationAccessSettings';

  static const String resync = 'resyncNotch';

  static const String mediaControl = 'mediaControl';

  static const String controlCommand = '__notchControl';

  static const String stopBoot = 'stop';
}

abstract final class NotchPrefs {
  const NotchPrefs._();

  static const String enabled = 'notch_enabled';

  static const String pending = 'notch_pending';

  static const String restore = 'notch_restore';
}
