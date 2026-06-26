import 'package:flutter/material.dart';

/// Central color tokens for the Neko app.
///
/// These values are the single source of truth for color across the app.
/// Onboarding screens are white; the home screen uses the warm amber-peach
/// [homeBg]; the brand accent is the coral [primary].
abstract final class AppColors {
  const AppColors._();

  // Backgrounds — the app uses one warm amber page background throughout;
  // white is reserved for cards/fields (surfaceCard) layered on top of it.
  static const Color background = Color(0xFFF5C275);
  static const Color homeBg = Color(0xFFF5C275);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// A subtle neutral fill for elements layered on a white card (e.g. an icon
  /// tile) where plain white would be invisible against the card.
  static const Color surfaceMuted = Color(0xFFF1ECE4);

  // Brand
  static const Color primary = Color(0xFFFF6B6B);
  static const Color primaryDark = Color(0xFFE85555);

  // Selection states
  static const Color selectedFill = Color(0xFFFFF0F0);
  static const Color selectedBorder = Color(0xFFFF6B6B);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Controls
  static const Color disabledBtn = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);

  // Surfaces
  static const Color darkBanner = Color(0xFF2F4F5E);

  // Semantic — reserved for calorie/progress states only.
  static const Color success = Color(0xFF58CC02);

  // Coat colors used for cat avatars when no photo is set.
  static const Color coatGinger = Color(0xFFFF8C42);
  static const Color coatBlack = Color(0xFF2D2D2D);
  static const Color coatWhite = Color(0xFFF0F0F0);
  static const Color coatTabby = Color(0xFF8B7355);
  static const Color coatCalico = Color(0xFFC8A882);
  static const Color coatGrey = Color(0xFF9E9E9E);
  static const Color coatTortoiseshell = Color(0xFFB8651B);
  static const Color coatOther = Color(0xFFBDBDBD);

  /// Maps a stored [colorType] string to its avatar color.
  ///
  /// Falls back to [coatOther] for unknown values so the UI never breaks on
  /// unexpected data.
  static Color catColorFor(String colorType) {
    return switch (colorType) {
      'ginger' => coatGinger,
      'black' => coatBlack,
      'white' => coatWhite,
      'tabby' => coatTabby,
      'calico' => coatCalico,
      'grey' => coatGrey,
      'tortoiseshell' => coatTortoiseshell,
      _ => coatOther,
    };
  }
}
