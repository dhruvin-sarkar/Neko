/// The activities the Neko Notch can surface, as a sealed hierarchy so the pill
/// and controller can pattern-match exhaustively.
///
/// Each activity carries its display [priority] and a [toLiveActivityData] map
/// whose keys must match what the native `NekoLiveActivityManager` reads when it
/// builds the system notification (the second, out-of-app layer).
library;

sealed class NotchActivity {
  const NotchActivity();

  ActivityPriority get priority;
  String get debugLabel;

  /// Data payload sent to `live_activities` for the system layer. Keys must
  /// match `NekoLiveActivityManager.kt`.
  Map<String, dynamic> toLiveActivityData();
}

// ─── URGENT ──────────────────────────────────────────────────────

final class IncomingCallActivity extends NotchActivity {
  const IncomingCallActivity({
    required this.callerName,
    required this.isVideo,
    this.callerAvatarUrl,
  });

  final String callerName;
  final bool isVideo;
  final String? callerAvatarUrl;

  @override
  ActivityPriority get priority => ActivityPriority.urgent;
  @override
  String get debugLabel => 'Call($callerName)';
  @override
  Map<String, dynamic> toLiveActivityData() => <String, dynamic>{
    'type': 'call',
    'callerName': callerName,
    'isVideo': isVideo,
  };
}

// ─── HIGH ────────────────────────────────────────────────────────

final class NavigationActivity extends NotchActivity {
  const NavigationActivity({
    required this.instruction,
    required this.distanceLabel,
    required this.direction,
    required this.etaLabel,
  });

  final String instruction;
  final String distanceLabel;

  /// One of 'north','northeast','east','southeast','south','southwest','west',
  /// 'northwest','uturn'.
  final String direction;
  final String etaLabel;

  @override
  ActivityPriority get priority => ActivityPriority.high;
  @override
  String get debugLabel => 'Nav($instruction)';
  @override
  Map<String, dynamic> toLiveActivityData() => <String, dynamic>{
    'type': 'nav',
    'instruction': instruction,
    'distanceLabel': distanceLabel,
    'direction': direction,
    'etaLabel': etaLabel,
  };
}

final class TimerActivity extends NotchActivity {
  const TimerActivity({
    required this.id,
    required this.label,
    required this.endsAt,
    required this.totalDuration,
  });

  final String id;
  final String label;
  final DateTime endsAt;
  final Duration totalDuration;

  int secondsLeftAt(DateTime now) {
    final int left = endsAt.difference(now).inSeconds;
    return left < 0 ? 0 : left;
  }

  double progressAt(DateTime now) {
    if (totalDuration.inMilliseconds == 0) return 0;
    final Duration left = endsAt.difference(now);
    return (1 - (left.inMilliseconds / totalDuration.inMilliseconds)).clamp(
      0.0,
      1.0,
    );
  }

  @override
  ActivityPriority get priority => ActivityPriority.high;
  @override
  String get debugLabel => 'Timer($label)';
  @override
  Map<String, dynamic> toLiveActivityData() => <String, dynamic>{
    'type': 'timer',
    'label': label,
    'secondsLeft': secondsLeftAt(DateTime.now()),
    'progress': progressAt(DateTime.now()),
  };
}

// ─── MEDIUM ──────────────────────────────────────────────────────

final class MusicActivity extends NotchActivity {
  const MusicActivity({
    required this.songTitle,
    required this.artistName,
    required this.isPlaying,
    required this.progress,
    this.albumArtUrl,
    this.source = 'unknown',
  });

  final String songTitle;
  final String artistName;
  final bool isPlaying;

  /// 0.0 → 1.0.
  final double progress;
  final String? albumArtUrl;
  final String source;

  @override
  ActivityPriority get priority => ActivityPriority.medium;
  @override
  String get debugLabel => 'Music($songTitle, playing=$isPlaying)';
  @override
  Map<String, dynamic> toLiveActivityData() => <String, dynamic>{
    'type': 'music',
    'songTitle': songTitle,
    'artistName': artistName,
    'isPlaying': isPlaying,
    'progress': progress,
    if (albumArtUrl != null) 'albumArtUrl': albumArtUrl,
  };
}

final class WorkoutActivity extends NotchActivity {
  const WorkoutActivity({
    required this.type,
    required this.durationSeconds,
    required this.steps,
    required this.caloriesBurned,
    this.heartRate,
  });

  /// 'running','walking','cycling','swimming','yoga','strength','hiit'.
  final String type;
  final int durationSeconds;
  final int steps;
  final int? heartRate;
  final double caloriesBurned;

  String get durationLabel {
    final int m = durationSeconds ~/ 60;
    final int s = durationSeconds % 60;
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  @override
  ActivityPriority get priority => ActivityPriority.medium;
  @override
  String get debugLabel => 'Workout($type)';
  @override
  Map<String, dynamic> toLiveActivityData() => <String, dynamic>{
    'type': 'workout',
    'workoutType': type,
    'durationLabel': durationLabel,
    'steps': steps,
    if (heartRate != null) 'heartRate': heartRate,
    'calories': caloriesBurned.toStringAsFixed(0),
  };
}

final class OrderTrackingActivity extends NotchActivity {
  const OrderTrackingActivity({
    required this.orderId,
    required this.restaurantName,
    required this.status,
    required this.etaMinutes,
    this.driverName,
  });

  final String orderId;
  final String restaurantName;

  /// 'placed','confirmed','preparing','outForDelivery','delivered'.
  final String status;
  final int etaMinutes;
  final String? driverName;

  String get statusLabel => switch (status) {
    'placed' => 'Order placed',
    'confirmed' => 'Confirmed',
    'preparing' => 'Being prepared',
    'outForDelivery' => 'On the way · ${etaMinutes}m',
    'delivered' => 'Delivered!',
    _ => status,
  };

  String get statusEmoji => switch (status) {
    'placed' => '🐾',
    'confirmed' => '✅',
    'preparing' => '🍳',
    'outForDelivery' => '🛵',
    'delivered' => '🎉',
    _ => '🐱',
  };

  @override
  ActivityPriority get priority => ActivityPriority.medium;
  @override
  String get debugLabel => 'Order($restaurantName, $status)';
  @override
  Map<String, dynamic> toLiveActivityData() => <String, dynamic>{
    'type': 'order',
    'restaurantName': restaurantName,
    'statusLabel': '$statusEmoji $statusLabel',
    'status': status,
  };
}

// ─── LOW ─────────────────────────────────────────────────────────

final class NotificationActivity extends NotchActivity {
  const NotificationActivity({
    required this.id,
    required this.appName,
    required this.title,
    required this.body,
  });

  final String id;
  final String appName;
  final String title;
  final String body;

  @override
  ActivityPriority get priority => ActivityPriority.low;
  @override
  String get debugLabel => 'Notif($appName: $title)';
  @override
  Map<String, dynamic> toLiveActivityData() => <String, dynamic>{
    'type': 'notification',
    'title': title,
    'body': body,
  };
}

final class BatteryActivity extends NotchActivity {
  const BatteryActivity({
    required this.percentage,
    required this.isCharging,
    this.minutesUntilFull,
  });

  final int percentage;
  final bool isCharging;
  final int? minutesUntilFull;

  @override
  ActivityPriority get priority => ActivityPriority.low;
  @override
  String get debugLabel => 'Battery($percentage%, charging=$isCharging)';
  @override
  Map<String, dynamic> toLiveActivityData() => <String, dynamic>{
    'type': 'battery',
    'title': isCharging ? '⚡ $percentage%' : '🔋 $percentage%',
    'body': minutesUntilFull != null ? '${minutesUntilFull}m until full' : '',
  };
}

// ─── HEY NEKO ────────────────────────────────────────────────────

final class HeyNekoActivity extends NotchActivity {
  const HeyNekoActivity({required this.phase, this.spokenText, this.response});

  final HeyNekoPhase phase;
  final String? spokenText;
  final String? response;

  @override
  ActivityPriority get priority => ActivityPriority.heyNeko;
  @override
  String get debugLabel => 'HeyNeko(${phase.name})';
  @override
  Map<String, dynamic> toLiveActivityData() => <String, dynamic>{
    'type': 'notification',
    'title': '🐱 Hey Neko',
    'body': response ?? spokenText ?? '...',
  };
}

// ─── ENUMS ───────────────────────────────────────────────────────

enum ActivityPriority {
  low(1),
  medium(2),
  high(3),
  urgent(4),
  heyNeko(99);

  const ActivityPriority(this.value);
  final int value;
}

enum HeyNekoPhase { waking, listening, thinking, responding, idle }
