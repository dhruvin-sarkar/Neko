import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography for the app.
///
/// I use Fredoka (plump and rounded) for the big "moment" text on a screen —
/// the headline or the question — and Nunito for everything interactive:
/// buttons, labels, inputs, body copy. The wide letter-spacing on button
/// labels is what gives them that game-UI feel.
abstract final class AppTextStyles {
  const AppTextStyles._();

  // Headlines — Fredoka, large and rounded.
  static final TextStyle displayLarge = GoogleFonts.fredoka(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.almostBlack,
    letterSpacing: -0.5,
  );

  static final TextStyle displayMedium = GoogleFonts.fredoka(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    color: AppColors.almostBlack,
    letterSpacing: -0.3,
  );

  static final TextStyle headlineLarge = GoogleFonts.fredoka(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.almostBlack,
  );

  // UI text — Nunito with the wide tracking Duolingo is known for.
  static final TextStyle titleMedium = GoogleFonts.nunito(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.almostBlack,
    letterSpacing: 0.3,
  );

  static final TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.almostBlack,
    letterSpacing: 0.3,
  );

  static final TextStyle bodyMedium = GoogleFonts.nunito(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.graphite,
    letterSpacing: 0.3,
  );

  static final TextStyle caption = GoogleFonts.nunito(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.silver,
    letterSpacing: 0.3,
  );

  // Buttons — Nunito, heavy, wide tracking. Labels render in uppercase.
  static final TextStyle buttonLabel = GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.snowWhite,
    letterSpacing: 1.2,
  );

  static final TextStyle buttonLabelDark = GoogleFonts.nunito(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: AppColors.almostBlack,
    letterSpacing: 1.2,
  );
}
