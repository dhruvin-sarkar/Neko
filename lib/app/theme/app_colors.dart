import 'package:flutter/material.dart';

import 'neko_palette.dart';

/// The single source of truth for colour in the app.
///
/// Every colour is read from the active [palette], which the theme picker swaps
/// at runtime. Because all widgets read these getters, swapping the palette (and
/// rebuilding) re-skins the entire app — light or dark. Only the cat-coat avatar
/// colours and a couple of fixed semantic tints stay constant.
abstract final class AppColors {
  const AppColors._();

  /// The active cat-coat theme. Swapped by the theme controller.
  static NekoPalette palette = NekoPalettes.gingerTabby;

  // Brand — driven by the active palette.
  static Color get primary => palette.primary;
  static Color get primaryDark => palette.primaryDark;
  static Color get primaryLight => palette.primaryLight;
  static Color get secondary => palette.secondary;

  // Semantic — success / warning / error follow the theme; their light/dark
  // tints and the info family stay constant.
  static Color get success => palette.success;
  static const Color successDark = Color(0xFF3F8F01);
  static const Color successLight = Color(0xFFD7FFB8);
  static Color get danger => palette.error;
  static const Color dangerDark = Color(0xFFCC0000);
  static const Color dangerLight = Color(0xFFFFE0E0);
  static const Color info = Color(0xFF1CB0F6);
  static const Color infoDark = Color(0xFF0A7AB8);
  static const Color infoLight = Color(0xFFDEF3FF);
  static Color get warning => palette.warning;

  // Text + neutrals — all per-theme now (warm-tinted, never pure black).
  static Color get almostBlack => palette.textPrimary; // primary text
  static Color get charcoal => palette.textSecondary; // subheadings
  static Color get graphite => palette.textTertiary; // body copy
  static Color get silver => palette.textTertiary; // placeholders, disabled
  static Color get cloudGray => palette.divider; // borders, dividers
  static Color get snowWhite => palette.surface; // card surfaces
  static Color get surfaceMuted => palette.inputFill; // tiles on cards

  // Surfaces.
  static Color get homeBg => palette.background;
  static Color get darkBanner => palette.banner;
  static Color get surfaceElevated => palette.surfaceElevated;
  static Color get inputFill => palette.inputFill;
  static Color get textOnPrimary => palette.textOnPrimary;
  static Color get navActive => palette.navActive;
  static Color get navInactive => palette.navInactive;
  static bool get isDark => palette.isDark;

  /// The tint of the drifting paw pattern behind every screen.
  static Color get pawPattern => palette.pawPattern;

  // Cat coat colours used for avatars when there's no photo (constant).
  static const Color coatGinger = Color(0xFFFF8C42);
  static const Color coatBlack = Color(0xFF2D2D2D);
  static const Color coatWhite = Color(0xFFF0F0F0);
  static const Color coatTabby = Color(0xFF8B7355);
  static const Color coatCalico = Color(0xFFC8A882);
  static const Color coatGrey = Color(0xFF9E9E9E);
  static const Color coatTortoiseshell = Color(0xFFB8651B);
  static const Color coatOther = Color(0xFFBDBDBD);

  // --- Semantic aliases (kept so existing widgets keep compiling) ---
  static Color get background => homeBg;
  static Color get surfaceCard => palette.surface;
  static Color get textPrimary => palette.textPrimary;
  static Color get textSecondary => palette.textSecondary;
  static Color get textDisabled => palette.textTertiary;
  static Color get border => palette.divider;
  static Color get selectedFill => palette.primaryLight;
  static Color get selectedBorder => palette.primary;
  static Color get disabledBtn => palette.divider;

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
