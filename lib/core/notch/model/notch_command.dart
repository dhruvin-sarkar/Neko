import 'dart:convert';

import 'package:flutter/material.dart';

import 'notch_activity.dart';

@immutable
class NotchTheme {
  const NotchTheme({
    required this.background,
    required this.foreground,
    required this.subdued,
    required this.accent,
    required this.isDark,
    this.topInset = 0,
  });

  final Color background;
  final Color foreground;
  final Color subdued;
  final Color accent;
  final bool isDark;

  final double topInset;

  static const NotchTheme fallback = NotchTheme(
    background: Color(0xFF0E0E10),
    foreground: Color(0xFFFFFFFF),
    subdued: Color(0xB3FFFFFF),
    accent: Color(0xFFF2564C),
    isDark: true,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'background': background.toARGB32(),
    'foreground': foreground.toARGB32(),
    'subdued': subdued.toARGB32(),
    'accent': accent.toARGB32(),
    'isDark': isDark,
    'topInset': topInset,
  };

  factory NotchTheme.fromJson(Map<String, dynamic> json) {
    Color read(String key, Color fallbackColor) {
      final Object? v = json[key];
      return v is num ? Color(v.toInt()) : fallbackColor;
    }

    return NotchTheme(
      background: read('background', NotchTheme.fallback.background),
      foreground: read('foreground', NotchTheme.fallback.foreground),
      subdued: read('subdued', NotchTheme.fallback.subdued),
      accent: read('accent', NotchTheme.fallback.accent),
      isDark: json['isDark'] != false,
      topInset: (json['topInset'] as num?)?.toDouble() ?? 0,
    );
  }
}

sealed class NotchCommand {
  const NotchCommand();

  static NotchCommand? tryParse(Object? raw) {
    Map<String, dynamic>? map;
    if (raw is String) {
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map) map = decoded.cast<String, dynamic>();
      } on FormatException {
        return null;
      }
    } else if (raw is Map) {
      map = raw.cast<String, dynamic>();
    }
    if (map == null) return null;

    switch (map['cmd']) {
      case 'push':
      case 'update':
        final Object? activity = map['activity'];
        if (activity is! Map) return null;
        final NotchActivity a = NotchActivity.fromJson(
          activity.cast<String, dynamic>(),
        );
        return map['cmd'] == 'push'
            ? PushActivityCommand(a)
            : UpdateActivityCommand(a);
      case 'remove':
        return RemoveActivityCommand(
          id: (map['id'] as Object?)?.toString(),
          type: map['removeType'] != null
              ? NotchActivityType.fromName(map['removeType'] as String?)
              : null,
        );
      case 'clear':
        return const ClearCommand();
      case 'theme':
        return NotchThemeCommand(NotchTheme.fromJson(map));
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson();

  String encode() => jsonEncode(toJson());
}

class PushActivityCommand extends NotchCommand {
  const PushActivityCommand(this.activity);
  final NotchActivity activity;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'cmd': 'push',
    'activity': activity.toJson(),
  };
}

class UpdateActivityCommand extends NotchCommand {
  const UpdateActivityCommand(this.activity);
  final NotchActivity activity;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'cmd': 'update',
    'activity': activity.toJson(),
  };
}

class RemoveActivityCommand extends NotchCommand {
  const RemoveActivityCommand({this.id, this.type});
  final String? id;
  final NotchActivityType? type;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'cmd': 'remove',
    if (id != null) 'id': id,
    if (type != null) 'removeType': type!.name,
  };
}

/// Clear
class ClearCommand extends NotchCommand {
  const ClearCommand();

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{'cmd': 'clear'};
}

class NotchThemeCommand extends NotchCommand {
  const NotchThemeCommand(this.theme);
  final NotchTheme theme;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'cmd': 'theme',
    ...theme.toJson(),
  };
}
