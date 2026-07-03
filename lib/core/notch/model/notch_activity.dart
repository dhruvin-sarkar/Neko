import 'package:flutter/foundation.dart';

/// live activity!
enum NotchActivityType {
  music,
  notification,
  timer,
  call,
  navigation,
  download,
  generic;

  static NotchActivityType fromName(String? name) {
    for (final NotchActivityType t in NotchActivityType.values) {
      if (t.name == name) return t;
    }
    return NotchActivityType.generic;
  }
}

@immutable
class NotchActivity {
  const NotchActivity({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle = '',
    this.appName,
    this.progress,
    this.isPlaying = false,
    this.durationMs,
    this.source,
    this.albumArt,
    bool? ongoing,
  }) : _ongoing = ongoing;

  final NotchActivityType type;

  final String id;

  final String title;
  final String subtitle;

  final String? appName;
  final double? progress;

  final bool isPlaying;

  final int? durationMs;


  final String? source;

  final String? albumArt;

  final bool? _ongoing;


  String get key => id.isNotEmpty ? id : type.name;

  bool get isOngoing =>
      _ongoing ??
      (type != NotchActivityType.notification &&
          type != NotchActivityType.generic);

  bool get isRestorable =>
      type == NotchActivityType.music || type == NotchActivityType.timer;

  NotchActivity copyWith({
    String? title,
    String? subtitle,
    String? appName,
    double? progress,
    bool? isPlaying,
    int? durationMs,
    String? source,
    String? albumArt,
    bool? ongoing,
  }) {
    return NotchActivity(
      type: type,
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      appName: appName ?? this.appName,
      progress: progress ?? this.progress,
      isPlaying: isPlaying ?? this.isPlaying,
      durationMs: durationMs ?? this.durationMs,
      source: source ?? this.source,
      albumArt: albumArt ?? this.albumArt,
      ongoing: ongoing ?? _ongoing,
    );
  }

  NotchActivity mergedWith(NotchActivity other) {
    return NotchActivity(
      type: other.type,
      id: other.id.isNotEmpty ? other.id : id,
      title: other.title.isNotEmpty ? other.title : title,
      subtitle: other.subtitle.isNotEmpty ? other.subtitle : subtitle,
      appName: other.appName ?? appName,
      progress: other.progress ?? progress,
      isPlaying: other.isPlaying,
      durationMs: other.durationMs ?? durationMs,
      source: other.source ?? source,
      albumArt: other.albumArt ?? albumArt,
      ongoing: other._ongoing ?? _ongoing,
    );
  }

  factory NotchActivity.fromJson(Map<String, dynamic> json) {
    final NotchActivityType type = NotchActivityType.fromName(
      json['type'] as String?,
    );

    final String title =
        (json['title'] ?? json['songTitle'] ?? '').toString();
    final String subtitle =
        (json['subtitle'] ?? json['artistName'] ?? json['body'] ?? '')
            .toString();
    final Object? rawProgress = json['progress'];
    final Object? rawDuration = json['durationMs'] ?? json['duration'];
    return NotchActivity(
      type: type,
      id: (json['id'] ?? '').toString(),
      title: title,
      subtitle: subtitle,
      appName: (json['appName'] as Object?)?.toString(),
      progress: rawProgress is num && rawProgress >= 0
          ? rawProgress.toDouble()
          : null,
      isPlaying: json['isPlaying'] == true || json['playing'] == true,
      durationMs: rawDuration is num ? rawDuration.toInt() : null,
      source: (json['source'] as Object?)?.toString(),
      albumArt: (json['albumArt'] as Object?)?.toString(),
      ongoing: json['ongoing'] is bool ? json['ongoing'] as bool : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'id': id,
      'title': title,
      'subtitle': subtitle,
      if (appName != null) 'appName': appName,
      if (progress != null) 'progress': progress,
      'isPlaying': isPlaying,
      'ongoing': isOngoing,
      if (durationMs != null) 'durationMs': durationMs,
      if (source != null) 'source': source,
      if (albumArt != null && albumArt!.isNotEmpty) 'albumArt': albumArt,
      if (type == NotchActivityType.music) ...<String, dynamic>{
        'songTitle': title,
        'artistName': subtitle,
      },
    };
  }
}
