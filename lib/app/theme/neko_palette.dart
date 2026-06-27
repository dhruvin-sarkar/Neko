import 'package:flutter/widgets.dart';

/// A selectable colour scheme for the app.
///
/// Only the *brand* colours change between themes — the accent (coral, ocean,
/// etc.), the warm page background, the dark banner, and the paw-pattern tint.
/// Neutrals (text, borders) and semantic colours (success/danger/info) stay
/// constant so contrast and meaning are preserved across every theme.
@immutable
class NekoPalette {
  const NekoPalette({
    required this.id,
    required this.label,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.background,
    required this.banner,
    required this.pawPattern,
  });

  /// Stable identifier persisted to storage.
  final String id;

  /// Human-friendly name shown in the theme picker.
  final String label;

  /// The brand accent — every CTA, logo, and active state.
  final Color primary;

  /// The 4px drop shadow under a primary button.
  final Color primaryDark;

  /// Selected card fill / active tints.
  final Color primaryLight;

  /// The warm page background the whole app sits on.
  final Color background;

  /// The dark pill-banner colour (cat banners, snackbars).
  final Color banner;

  /// The tint of the drifting paw pattern in the background.
  final Color pawPattern;
}

/// The built-in themes. [coral] is the original default.
abstract final class NekoPalettes {
  const NekoPalettes._();

  static const NekoPalette coral = NekoPalette(
    id: 'coral',
    label: 'Coral Sunrise',
    primary: Color(0xFFFF6B6B),
    primaryDark: Color(0xFFCC4444),
    primaryLight: Color(0xFFFFE5E5),
    background: Color(0xFFF5C275),
    banner: Color(0xFF2F4F5E),
    pawPattern: Color(0xFFFF5C8D),
  );

  static const NekoPalette ocean = NekoPalette(
    id: 'ocean',
    label: 'Seaside',
    primary: Color(0xFFFF7043), // warm coral-orange that pops on teal
    primaryDark: Color(0xFFC9482A),
    primaryLight: Color(0xFFFFE0D6),
    background: Color(0xFF5FB7D4), // teal-blue
    banner: Color(0xFF1F4654),
    pawPattern: Color(0xFFFF7A4D), // warm coral paws contrast the teal
  );

  static const NekoPalette forest = NekoPalette(
    id: 'forest',
    label: 'Meadow',
    primary: Color(0xFFE8568A), // berry pink against the green
    primaryDark: Color(0xFFB62E63),
    primaryLight: Color(0xFFFCD9E6),
    background: Color(0xFF8DCB79), // leaf green
    banner: Color(0xFF2C4030),
    pawPattern: Color(0xFFE8568A), // berry-pink paws contrast the green
  );

  static const NekoPalette lavender = NekoPalette(
    id: 'lavender',
    label: 'Twilight',
    primary: Color(0xFFFFB72B), // golden accent on lavender
    primaryDark: Color(0xFFCC8A12),
    primaryLight: Color(0xFFFFEFC9),
    background: Color(0xFFB79CE0), // soft lavender
    banner: Color(0xFF38304E),
    pawPattern: Color(0xFFFFC24B), // golden paws contrast the lavender
  );

  static const NekoPalette blush = NekoPalette(
    id: 'blush',
    label: 'Bubblegum',
    primary: Color(0xFF2BB5A8), // teal accent on pink
    primaryDark: Color(0xFF178C82),
    primaryLight: Color(0xFFCFF2EE),
    background: Color(0xFFF4A0C0), // bubblegum pink
    banner: Color(0xFF4E2E3E),
    pawPattern: Color(0xFF2BB5A8), // teal paws contrast the pink
  );

  /// All themes, in display order.
  static const List<NekoPalette> all = <NekoPalette>[
    coral,
    ocean,
    forest,
    lavender,
    blush,
  ];

  /// Resolves a palette by [id], falling back to [coral].
  static NekoPalette byId(String? id) {
    for (final NekoPalette p in all) {
      if (p.id == id) return p;
    }
    return coral;
  }
}
