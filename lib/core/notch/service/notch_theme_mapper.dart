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

  /// WCAG relative-contrast ratio between two opaque colours (1.0 .. 21.0).
  static double _contrast(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double hi = la > lb ? la : lb;
    final double lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  static NotchTheme fromPalette(NekoPalette palette, {double topInset = 0}) {
    final bool dark = palette.isDark;

    // Dark themes: the elevated surface already blends with the cutout.
    // Light themes: every palette's primaryDark is a saturated HUE (brick,
    // mustard, espresso, indigo) that would read as coloured glass beside the
    // black camera — so drop it to near-ink UNCONDITIONALLY, keeping only a
    // faint coat tint. (The old `> 0.16` gate never fired: every primaryDark is
    // already below it, so the island rendered as a fully-saturated dark hue.)
    Color background = dark
        ? palette.surfaceElevated
        : (Color.lerp(palette.primaryDark, _inkBase, 0.72) ?? _inkBase);
    // Safety net for any dark palette whose elevated surface is too light to
    // pass for a cutout.
    if (background.computeLuminance() > 0.16) {
      background = Color.lerp(background, _inkBase, 0.78) ?? _inkBase;
    }

    // Foreground sits on the dark island, not on the app surface — so it must
    // be light regardless of what the palette uses on primary.
    Color foreground = dark ? palette.textPrimary : palette.textOnPrimary;
    if (foreground.computeLuminance() < 0.45) {
      foreground = _softWhite;
    }

    // Accent drives the waves/progress/ears AND the timer countdown text and
    // the nav route line — the most glanceable elements — so it has to actually
    // contrast with the island ink, not merely avoid being near-black. A fixed
    // luminance floor let mid-luminance coats (sealPoint's muted brown) sit at
    // ~2.4:1 on the dark background. Guard on real WCAG contrast against the
    // background we just computed, stepping to the secondary and then a soft
    // white until it clears the 3.0 floor the palette contrast test enforces.
    Color accent = palette.primary;
    if (_contrast(accent, background) < 3.0) {
      accent = palette.secondary;
      if (_contrast(accent, background) < 3.0) {
        accent = Color.lerp(accent, _softWhite, 0.5) ?? _softWhite;
      }
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
