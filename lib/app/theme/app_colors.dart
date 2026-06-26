import 'package:flutter/material.dart';

/// The single source of truth for colour in the app.
///
/// Coral is our brand accent (it plays the role Duolingo's green plays for
/// them): it appears once per screen, on the main call-to-action. Pages sit on
/// the warm amber background; white is reserved for the cards and fields that
/// sit on top of it. I keep a few legacy names as aliases at the bottom so
/// older widgets keep working while pointing at the same canonical values.
abstract final class AppColors {
  const AppColors._();

  // Brand — coral
  static const Color primary = Color(
    0xFFFF6B6B,
  ); // every CTA, logo, active state
  static const Color primaryDark = Color(
    0xFFCC4444,
  ); // the 4px shadow under a coral button
  static const Color primaryLight = Color(
    0xFFFFE5E5,
  ); // selected card fill, active tints

  // Semantic — success (the only place I use green)
  static const Color success = Color(0xFF58CC02);
  static const Color successDark = Color(0xFF3F8F01);
  static const Color successLight = Color(0xFFD7FFB8);

  // Semantic — danger / errors
  static const Color danger = Color(0xFFFF4B4B);
  static const Color dangerDark = Color(0xFFCC0000);
  static const Color dangerLight = Color(0xFFFFE0E0);

  // Semantic — info / links / secondary actions
  static const Color info = Color(0xFF1CB0F6);
  static const Color infoDark = Color(0xFF0A7AB8);
  static const Color infoLight = Color(0xFFDEF3FF);

  // Semantic — warning / streaks
  static const Color warning = Color(0xFFFFC700);

  // Neutrals — I never use pure black or `Colors.grey`.
  static const Color almostBlack = Color(0xFF3C3C3C); // primary text
  static const Color charcoal = Color(0xFF4B4B4B); // subheadings
  static const Color graphite = Color(0xFF777777); // body copy, descriptions
  static const Color silver = Color(0xFFAFAFAF); // placeholders, disabled text
  static const Color cloudGray = Color(0xFFE5E5E5); // borders, dividers
  static const Color snowWhite = Color(0xFFFFFFFF); // card surfaces

  // Surfaces
  static const Color homeBg = Color(0xFFF5C275); // warm amber page background
  static const Color darkBanner = Color(0xFF2F4F5E); // cat profile pill banners

  /// A subtle neutral fill for elements layered on a white card (e.g. an icon
  /// tile) where plain white would be invisible against the card.
  static const Color surfaceMuted = Color(0xFFF1ECE4);

  // Cat coat colours used for avatars when there's no photo.
  static const Color coatGinger = Color(0xFFFF8C42);
  static const Color coatBlack = Color(0xFF2D2D2D);
  static const Color coatWhite = Color(0xFFF0F0F0);
  static const Color coatTabby = Color(0xFF8B7355);
  static const Color coatCalico = Color(0xFFC8A882);
  static const Color coatGrey = Color(0xFF9E9E9E);
  static const Color coatTortoiseshell = Color(0xFFB8651B);
  static const Color coatOther = Color(0xFFBDBDBD);

  // --- Legacy aliases (kept so existing widgets keep compiling) ---
  static const Color background = homeBg; // every page sits on amber
  static const Color surfaceCard = snowWhite;
  static const Color textPrimary = almostBlack;
  static const Color textSecondary = graphite;
  static const Color textDisabled = silver;
  static const Color border = cloudGray;
  static const Color selectedFill = primaryLight;
  static const Color selectedBorder = primary;
  static const Color disabledBtn = cloudGray;

  /// Maps a stored [colorType] string to its avatar colour, falling back to a
  /// neutral so unexpected data never breaks the UI.
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
