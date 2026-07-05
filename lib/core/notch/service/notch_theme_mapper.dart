import 'package:flutter/painting.dart' show Color;

import '../../../app/theme/neko_palette.dart';
import '../model/notch_command.dart';

/// Maps the app's coat palette onto the notch island.
///
/// The island fakes a hardware cutout, so its background must stay dark in
/// every one of the twelve palettes — a bright island next to the black
/// punch-hole camera reads as broken glass, not a Dynamic Island. Light themes
/// therefore tint a dark base with the palette's primary rather than using a
/// light surface, and the foreground/accent are luminance-guarded so no palette
/// (e.g. tuxedo, whose on-primary text is near-black) can produce invisible
/// text on the dark island.
abstract final class NotchThemeMapper {
  const NotchThemeMapper._();

  static const Color _inkBase = Color(0xFF0B0B0E);
  static const Color _softWhite = Color(0xFFF6F6F8);

  static NotchTheme fromPalette(NekoPalette palette, {double topInset = 0}) {
    final bool dark = palette.isDark;

    // Dark themes: the elevated surface already blends with the cutout.
    // Light themes: a deep, primary-tinted ink — themed but unmistakably dark.
    Color background = dark ? palette.surfaceElevated : palette.primaryDark;
    if (background.computeLuminance() > 0.16) {
      background = Color.lerp(background, _inkBase, 0.78) ?? _inkBase;
    }

    // Foreground sits on the dark island, not on the app surface — so it must
    // be light regardless of what the palette uses on primary.
    Color foreground = dark ? palette.textPrimary : palette.textOnPrimary;
    if (foreground.computeLuminance() < 0.45) {
      foreground = _softWhite;
    }

    // Accent drives waves/progress/ears; keep it visible against the ink.
    Color accent = palette.primary;
    if (accent.computeLuminance() < 0.06) {
      accent = palette.secondary;
    }

    return NotchTheme(
      background: background,
      foreground: foreground,
      subdued: foreground.withValues(alpha: 0.7),
      accent: accent,
      isDark: dark,
      topInset: topInset,
    );
  }
}
