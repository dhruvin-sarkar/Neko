import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography for the app.
///
/// I use Fredoka (plump and rounded) for the big "moment" text on a screen —
/// the headline or the question — and Nunito for everything interactive:
/// buttons, labels, inputs, body copy. The wide letter-spacing on button
/// labels is what gives them that game-UI feel.
///
/// These are **getters**, not `static final` fields, on purpose: the colour is
/// read from the active [AppColors] palette on every access. A `static final`
/// would bake the colour once (at first access, under whatever theme was
/// active then) and never update — so text would keep the first theme's colour
/// forever and vanish on dark themes.
abstract final class AppTextStyles {
  const AppTextStyles._();

  // Headlines — Fredoka, large and rounded.
  static TextStyle get displayLarge => GoogleFonts.fredoka(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.almostBlack,
    letterSpacing: -0.5,
  );

  static TextStyle get displayMedium => GoogleFonts.fredoka(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.almostBlack,
    letterSpacing: -0.3,
  );

  static TextStyle get headlineLarge => GoogleFonts.fredoka(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.almostBlack,
  );

  // UI text — Nunito with the wide tracking Duolingo is known for.
  static TextStyle get titleMedium => GoogleFonts.nunito(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.almostBlack,
    letterSpacing: 0.3,
  );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.almostBlack,
    letterSpacing: 0.3,
  );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.graphite,
    letterSpacing: 0.3,
  );

  static TextStyle get caption => GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.silver,
    letterSpacing: 0.3,
  );

  // Buttons — Nunito, heavy, wide tracking. Labels render in uppercase.
  static TextStyle get buttonLabel => GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.snowWhite,
    letterSpacing: 1.2,
  );

  static TextStyle get buttonLabelDark => GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.almostBlack,
    letterSpacing: 1.2,
  );
}
