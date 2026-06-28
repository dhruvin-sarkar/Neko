import 'package:flutter/material.dart';

import '../../shared/motion/page_transitions.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Builds the single Material 3 [ThemeData] used by the app.
///
/// The flat "Duolingo depth" drop-shadow on primary CTAs lives in the custom
/// button widgets (they need a zero-blur offset shadow that Material elevation
/// can't express). This theme keeps Material components on-brand for any
/// incidental use.
abstract final class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    final Brightness brightness = AppColors.isDark
        ? Brightness.dark
        : Brightness.light;
    final ColorScheme colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          surface: AppColors.surfaceCard,
          onSurface: AppColors.textPrimary,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: NekoPageTransitionsBuilder(),
          TargetPlatform.iOS: NekoPageTransitionsBuilder(),
          TargetPlatform.macOS: NekoPageTransitionsBuilder(),
          TargetPlatform.windows: NekoPageTransitionsBuilder(),
          TargetPlatform.linux: NekoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: NekoPageTransitionsBuilder(),
        },
      ),
      filledButtonTheme: _filledButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: AppColors.primary.withValues(alpha: 0.06),
    );
  }

  static TextTheme get _textTheme => TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    headlineLarge: AppTextStyles.headlineLarge,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    labelLarge: AppTextStyles.buttonLabel,
    bodySmall: AppTextStyles.caption,
  );

  static FilledButtonThemeData get _filledButtonTheme => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.disabledBtn,
      disabledForegroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      textStyle: AppTextStyles.buttonLabel,
    ),
  );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 56),
          side: BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: AppTextStyles.buttonLabel,
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
      textStyle: AppTextStyles.bodyMedium,
    ),
  );

  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceCard,
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.primaryDark),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
    ),
  );
}
