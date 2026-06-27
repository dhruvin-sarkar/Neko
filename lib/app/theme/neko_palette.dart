import 'package:flutter/widgets.dart';

/// A selectable brand colour scheme. Only brand colours change between themes;
/// neutrals and semantic colours stay constant.
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

  /// Persisted identifier.
  final String id;

  /// Name shown in the theme picker.
  final String label;

  /// Brand accent: CTAs, logo, active states.
  final Color primary;

  /// Drop shadow under a primary button.
  final Color primaryDark;

  /// Selected fills and active tints.
  final Color primaryLight;

  /// Page background.
  final Color background;

  /// Dark pill-banner colour.
  final Color banner;

  /// Tint of the drifting paw pattern.
  final Color pawPattern;
}

/// Built-in themes; [coral] is the default.
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

  // Every theme shares Coral's warm accent-on-soft-background look, varying
  // only the background hue.

  static const NekoPalette ocean = NekoPalette(
    id: 'ocean',
    label: 'Seaside',
    primary: Color(0xFFFF7B62),
    primaryDark: Color(0xFFD4543C),
    primaryLight: Color(0xFFFFE3DB),
    background: Color(0xFF7FC3C2), // muted seafoam
    banner: Color(0xFF234A50),
    pawPattern: Color(0xFFFF9478),
  );

  static const NekoPalette forest = NekoPalette(
    id: 'forest',
    label: 'Meadow',
    primary: Color(0xFFE96F57), // terracotta-rose
    primaryDark: Color(0xFFBE4A36),
    primaryLight: Color(0xFFFBE1DA),
    background: Color(0xFFAEC982), // dusty sage
    banner: Color(0xFF33442C),
    pawPattern: Color(0xFFF2906F),
  );

  static const NekoPalette lavender = NekoPalette(
    id: 'lavender',
    label: 'Twilight',
    primary: Color(0xFFFFA63D), // amber-gold
    primaryDark: Color(0xFFD17E1A),
    primaryLight: Color(0xFFFFEBD2),
    background: Color(0xFFB3A2D6), // dusty lavender
    banner: Color(0xFF382F4E),
    pawPattern: Color(0xFFFFBC63),
  );

  static const NekoPalette blush = NekoPalette(
    id: 'blush',
    label: 'Bubblegum',
    primary: Color(0xFFFF7E63), // warm coral
    primaryDark: Color(0xFFD5573C),
    primaryLight: Color(0xFFFFE3DB),
    background: Color(0xFFF2A6BC), // dusty rose
    banner: Color(0xFF4A2733),
    pawPattern: Color(0xFFFF9B7B),
  );

  /// All themes, in display order.
  static const List<NekoPalette> all = <NekoPalette>[
    coral,
    ocean,
    forest,
    lavender,
    blush,
  ];

  /// Returns the palette for [id], or [coral] if unknown.
  static NekoPalette byId(String? id) {
    for (final NekoPalette p in all) {
      if (p.id == id) return p;
    }
    return coral;
  }
}
