import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'neko_colors.dart';
import 'neko_typography.dart';

abstract final class NekoTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: NekoColors.primary,
      onPrimary: Colors.white,
      secondary: NekoColors.secondary,
      onSecondary: NekoColors.textPrimary,
      surface: NekoColors.surface,
      onSurface: NekoColors.textPrimary,
      error: NekoColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NekoColors.background,
      textTheme: TextTheme(
        displayLarge: NekoTypography.display(),
        titleLarge: NekoTypography.title(),
        bodyLarge: NekoTypography.body(),
        bodyMedium: NekoTypography.body(size: 14),
        labelLarge: NekoTypography.label(),
        labelSmall: NekoTypography.caption(size: 11),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NekoColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: BorderSide(color: NekoColors.secondary.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: NekoColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(100),
          borderSide: const BorderSide(color: NekoColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
    );
  }
}
