import 'package:flutter/painting.dart' show Color;

import '../../../app/theme/neko_palette.dart';
import '../model/notch_command.dart';

abstract final class NotchThemeMapper {
  const NotchThemeMapper._();

  static NotchTheme fromPalette(NekoPalette palette, {double topInset = 0}) {
    final bool dark = palette.isDark;
    final Color foreground = dark ? palette.textPrimary : palette.textOnPrimary;
    return NotchTheme(
      background: dark ? palette.surfaceElevated : palette.primaryDark,
      foreground: foreground,
      subdued: foreground.withValues(alpha: 0.7),
      accent: palette.primary,
      isDark: dark,
      topInset: topInset,
    );
  }
}
