import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'neko_colors.dart';

abstract final class NekoTypography {
  static TextStyle display({double size = 42, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color ?? NekoColors.textPrimary,
      );

  static TextStyle title({double size = 24, Color? color}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? NekoColors.textPrimary,
      );

  static TextStyle body({double size = 16, Color? color}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: color ?? NekoColors.textPrimary,
      );

  static TextStyle caption({double size = 12, Color? color}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: color ?? NekoColors.textSecondary,
      );

  static TextStyle label({double size = 14, Color? color}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? NekoColors.textPrimary,
      );
}
