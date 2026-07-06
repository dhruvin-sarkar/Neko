import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography for the app.
///
/// I use Fredoka (plump and rounded) for the big "moment" text on a screen —
/// the headline or the question — and Nunito for everything interactive:
/// buttons, labels, inputs, body copy. The wide letter-spacing on button
/// labels is what gives them that game-UI feel.
///
/// The fonts are **bundled** (assets/fonts, declared in pubspec) rather than
/// fetched at runtime by google_fonts — so the very first cold-start frame
/// already renders in Fredoka/Nunito with no flash of a fallback font, and the
/// app looks right even offline. The variable TTFs interpolate every weight
/// used below from the single family file. (The Google sign-in button keeps
/// google_fonts' Roboto — that's Google's own branding requirement.)
///
/// These are **getters**, not `static final` fields, on purpose: the colour is
/// read from the active [AppColors] palette on every access. A `static final`
/// would bake the colour once (at first access, under whatever theme was
/// active then) and never update — so text would keep the first theme's colour
/// forever and vanish on dark themes.
abstract final class AppTextStyles {
  const AppTextStyles._();

  /// Bundled family names (see pubspec `flutter: fonts:`).
  static const String fredoka = 'Fredoka';
  static const String nunito = 'Nunito';

  // Headlines — Fredoka, large and rounded.
  static TextStyle get displayLarge => const TextStyle(
    fontFamily: fredoka,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  ).copyWith(color: AppColors.almostBlack);

  static TextStyle get displayMedium => const TextStyle(
    fontFamily: fredoka,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  ).copyWith(color: AppColors.almostBlack);

  static TextStyle get headlineLarge => const TextStyle(
    fontFamily: fredoka,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  ).copyWith(color: AppColors.almostBlack);

  // UI text — Nunito with the wide tracking Duolingo is known for.
  static TextStyle get titleMedium => const TextStyle(
    fontFamily: nunito,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  ).copyWith(color: AppColors.almostBlack);

  static TextStyle get bodyLarge => const TextStyle(
    fontFamily: nunito,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  ).copyWith(color: AppColors.almostBlack);

  static TextStyle get bodyMedium => const TextStyle(
    fontFamily: nunito,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  ).copyWith(color: AppColors.graphite);

  static TextStyle get caption => const TextStyle(
    fontFamily: nunito,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  ).copyWith(color: AppColors.silver);

  // Buttons — Nunito, heavy, wide tracking. Labels render in uppercase.
  static TextStyle get buttonLabel => const TextStyle(
    fontFamily: nunito,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  ).copyWith(color: AppColors.snowWhite);

  static TextStyle get buttonLabelDark => const TextStyle(
    fontFamily: nunito,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
  ).copyWith(color: AppColors.almostBlack);
}
