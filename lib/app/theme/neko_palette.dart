import 'package:flutter/widgets.dart';

/// A full colour theme derived from a real cat coat. Every per-theme colour the
/// app needs lives here; [AppColors] reads the active palette, so swapping it
/// re-skins the whole app (light or dark).
///
/// These are *whole* palettes, not accent swaps: each theme owns its own
/// background, surfaces, text and dividers, so switching themes visibly changes
/// the entire canvas — not just the buttons.
@immutable
class NekoPalette {
  const NekoPalette({
    required this.id,
    required this.label,
    required this.emoji,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.secondary,
    required this.surface,
    required this.surfaceElevated,
    required this.background,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnPrimary,
    required this.divider,
    required this.success,
    required this.warning,
    required this.error,
    required this.navInactive,
    required this.isDark,
  });

  /// Persisted identifier.
  final String id;

  /// Name shown in the theme picker.
  final String label;

  /// Emoji shown beside the name in the picker.
  final String emoji;

  /// Brand accent: CTAs, logo, active states.
  final Color primary;

  /// Drop shadow under a primary button.
  final Color primaryDark;

  /// Selected fills and active tints.
  final Color primaryLight;

  /// Highlights, badges, accent icons.
  final Color secondary;

  /// Card background.
  final Color surface;

  /// Modals / sheets.
  final Color surfaceElevated;

  /// Page background.
  final Color background;

  /// Text field background.
  final Color inputFill;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Foreground on top of [primary].
  final Color textOnPrimary;

  /// Borders and dividers.
  final Color divider;

  final Color success;
  final Color warning;
  final Color error;

  /// Inactive nav item colour. Active = [primary].
  final Color navInactive;

  /// Whether this is a dark theme (drives [ThemeData.brightness]).
  final bool isDark;

  /// Active nav item — always the brand accent.
  Color get navActive => primary;

  /// The cat-profile pill banner: a deep, on-brand fill that the banner's
  /// light text sits on. On dark themes the elevated surface reads as the
  /// "raised" banner; on light themes the deep primary-dark is the banner.
  Color get banner => isDark ? surfaceElevated : primaryDark;

  /// Tint of the drifting paw pattern (drawn at low opacity).
  Color get pawPattern => primary;
}

/// The twelve cat-coat themes. [gingerTabby] (Ginger & Coral) is the default —
/// the warm amber + coral identity the app ships with. Nine are light with
/// distinct backgrounds; three (Midnight, Havana, Tuxedo) are full dark themes.
abstract final class NekoPalettes {
  const NekoPalettes._();

  // ── Default: warm amber background, coral accent, amber secondary ──────────
  static const NekoPalette gingerTabby = NekoPalette(
    id: 'gingerTabby',
    label: 'Ginger & Coral',
    emoji: '🧡',
    primary: Color(0xFFF2564C),
    primaryDark: Color(0xFF8F2A22),
    primaryLight: Color(0xFFFFE1DA),
    secondary: Color(0xFFFFA63D),
    surface: Color(0xFFFFFCFA),
    surfaceElevated: Color(0xFFFFF6EF),
    background: Color(0xFFFFEEDF),
    inputFill: Color(0xFFFCE3D2),
    textPrimary: Color(0xFF3A1E13),
    textSecondary: Color(0xFF7C4630),
    textTertiary: Color(0xFFA9745A),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFF6D2BD),
    success: Color(0xFF3F8F43),
    warning: Color(0xFFE07B00),
    error: Color(0xFFD8362B),
    navInactive: Color(0xFFA57860),
    isDark: false,
  );

  // ── Sunny honey cream ──────────────────────────────────────────────────────
  static const NekoPalette creamBeige = NekoPalette(
    id: 'creamBeige',
    label: 'Cream & Honey',
    emoji: '🍯',
    primary: Color(0xFFE2991C),
    primaryDark: Color(0xFF8A5C00),
    primaryLight: Color(0xFFFFEFC2),
    secondary: Color(0xFFF4845F),
    surface: Color(0xFFFFFDF6),
    surfaceElevated: Color(0xFFFFF9E8),
    background: Color(0xFFFFF4D6),
    inputFill: Color(0xFFFAEAC0),
    textPrimary: Color(0xFF3A2A06),
    textSecondary: Color(0xFF6E521A),
    textTertiary: Color(0xFF9C7B36),
    textOnPrimary: Color(0xFF3A2600),
    divider: Color(0xFFF1DEA6),
    success: Color(0xFF4E9A2F),
    warning: Color(0xFFD98A1E),
    error: Color(0xFFD84545),
    navInactive: Color(0xFF97803F),
    isDark: false,
  );

  // ── Warm autumnal tan, burnt-orange accent ─────────────────────────────────
  static const NekoPalette tortoiseshell = NekoPalette(
    id: 'tortoiseshell',
    label: 'Tortoiseshell',
    emoji: '🍂',
    primary: Color(0xFFB1551F),
    primaryDark: Color(0xFF6E330F),
    primaryLight: Color(0xFFF8DEC8),
    secondary: Color(0xFFC79016),
    surface: Color(0xFFFCF6EE),
    surfaceElevated: Color(0xFFF6EADB),
    background: Color(0xFFEFDFC9),
    inputFill: Color(0xFFE9D5BB),
    textPrimary: Color(0xFF301606),
    textSecondary: Color(0xFF5C3114),
    textTertiary: Color(0xFF8A5A33),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFDCC2A2),
    success: Color(0xFF3E8B3A),
    warning: Color(0xFFC9871A),
    error: Color(0xFFC0392B),
    navInactive: Color(0xFFA37B53),
    isDark: false,
  );

  // ── Playful tri-colour: orange primary, plum secondary ─────────────────────
  static const NekoPalette calico = NekoPalette(
    id: 'calico',
    label: 'Calico Carnival',
    emoji: '🎨',
    primary: Color(0xFFE9531F),
    primaryDark: Color(0xFF952E09),
    primaryLight: Color(0xFFFFE0D2),
    secondary: Color(0xFF7E3F9E),
    surface: Color(0xFFFFFAF6),
    surfaceElevated: Color(0xFFFEF1E9),
    background: Color(0xFFFCE9DC),
    inputFill: Color(0xFFFADCC9),
    textPrimary: Color(0xFF34160A),
    textSecondary: Color(0xFF6B2D14),
    textTertiary: Color(0xFF9A5A3E),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFF3CBB4),
    success: Color(0xFF3F8F43),
    warning: Color(0xFFE08200),
    error: Color(0xFFC92F22),
    navInactive: Color(0xFFB98168),
    isDark: false,
  );

  // ── Crisp cool airy white, periwinkle accent ───────────────────────────────
  static const NekoPalette snowWhite = NekoPalette(
    id: 'snowWhite',
    label: 'Snow White',
    emoji: '🤍',
    primary: Color(0xFF6173E0),
    primaryDark: Color(0xFF36419E),
    primaryLight: Color(0xFFE5E8FF),
    secondary: Color(0xFFF18FBA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF6F8FF),
    background: Color(0xFFEAEEFB),
    inputFill: Color(0xFFEAEDFB),
    textPrimary: Color(0xFF181B33),
    textSecondary: Color(0xFF474C6E),
    textTertiary: Color(0xFF7C8099),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFD7DCF2),
    success: Color(0xFF2E9E6B),
    warning: Color(0xFFE08A00),
    error: Color(0xFFDC3F45),
    navInactive: Color(0xFF767DA0),
    isDark: false,
  );

  // ── Cool muted slate-blue ──────────────────────────────────────────────────
  static const NekoPalette russianBlue = NekoPalette(
    id: 'russianBlue',
    label: 'Russian Blue',
    emoji: '🔵',
    primary: Color(0xFF456B80),
    primaryDark: Color(0xFF243F4C),
    primaryLight: Color(0xFFDCE7EC),
    secondary: Color(0xFF4FA89E),
    surface: Color(0xFFF6FAFC),
    surfaceElevated: Color(0xFFEAF1F5),
    background: Color(0xFFDCE7ED),
    inputFill: Color(0xFFD6E2E8),
    textPrimary: Color(0xFF15252E),
    textSecondary: Color(0xFF3A535F),
    textTertiary: Color(0xFF647C88),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFC0D0D8),
    success: Color(0xFF2E9E7E),
    warning: Color(0xFFE08A00),
    error: Color(0xFFD94A48),
    navInactive: Color(0xFF6C8794),
    isDark: false,
  );

  // ── Cool silver-grey, steel accent ─────────────────────────────────────────
  static const NekoPalette silverTabby = NekoPalette(
    id: 'silverTabby',
    label: 'Silver Chinchilla',
    emoji: '✨',
    primary: Color(0xFF53758A),
    primaryDark: Color(0xFF2E4654),
    primaryLight: Color(0xFFE2EAEF),
    secondary: Color(0xFF3FA886),
    surface: Color(0xFFF9FBFC),
    surfaceElevated: Color(0xFFEFF3F6),
    background: Color(0xFFE3EAEF),
    inputFill: Color(0xFFDEE6EB),
    textPrimary: Color(0xFF1A2730),
    textSecondary: Color(0xFF3F525E),
    textTertiary: Color(0xFF6E828E),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFC8D3DA),
    success: Color(0xFF36996F),
    warning: Color(0xFFD98A1E),
    error: Color(0xFFD8443F),
    navInactive: Color(0xFF728693),
    isDark: false,
  );

  // ── Soft lavender, lilac accent ────────────────────────────────────────────
  static const NekoPalette lilacLavender = NekoPalette(
    id: 'lilacLavender',
    label: 'Lilac Whisper',
    emoji: '💜',
    primary: Color(0xFF7E5BC2),
    primaryDark: Color(0xFF4D2F8A),
    primaryLight: Color(0xFFEDE4FF),
    secondary: Color(0xFFE980AE),
    surface: Color(0xFFFEFBFF),
    surfaceElevated: Color(0xFFF6EEFF),
    background: Color(0xFFEFE6FC),
    inputFill: Color(0xFFEADFFB),
    textPrimary: Color(0xFF1F1138),
    textSecondary: Color(0xFF4B3577),
    textTertiary: Color(0xFF7C68A6),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFDDCFF2),
    success: Color(0xFF479E5A),
    warning: Color(0xFFDD8A12),
    error: Color(0xFFD9484D),
    navInactive: Color(0xFF897AAC),
    isDark: false,
  );

  // ── Elegant warm taupe, seal-brown accent ──────────────────────────────────
  static const NekoPalette sealPoint = NekoPalette(
    id: 'sealPoint',
    label: 'Siamese Dreams',
    emoji: '👑',
    primary: Color(0xFF6D4C41),
    primaryDark: Color(0xFF3E2723),
    primaryLight: Color(0xFFEDE2DA),
    secondary: Color(0xFF6E8CA0),
    surface: Color(0xFFFBF7F3),
    surfaceElevated: Color(0xFFF3EAE2),
    background: Color(0xFFEBE0D6),
    inputFill: Color(0xFFE5D8CC),
    textPrimary: Color(0xFF241410),
    textSecondary: Color(0xFF4E342E),
    textTertiary: Color(0xFF7A6157),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFD6C7BB),
    success: Color(0xFF3F8F43),
    warning: Color(0xFFC9871A),
    error: Color(0xFFB23A2E),
    navInactive: Color(0xFFA08A7E),
    isDark: false,
  );

  // ── Dark: midnight indigo, lavender accent ─────────────────────────────────
  static const NekoPalette midnightBlack = NekoPalette(
    id: 'midnightBlack',
    label: 'Midnight Black',
    emoji: '⚫',
    primary: Color(0xFFBB86FC),
    primaryDark: Color(0xFF7B3FBF),
    primaryLight: Color(0xFF2A1A45),
    secondary: Color(0xFF03DAC6),
    surface: Color(0xFF1E1A2C),
    surfaceElevated: Color(0xFF2A2541),
    background: Color(0xFF121019),
    inputFill: Color(0xFF272239),
    textPrimary: Color(0xFFEDE8FF),
    textSecondary: Color(0xFFB4ABD0),
    textTertiary: Color(0xFF8077A0),
    textOnPrimary: Color(0xFF1A0E2E),
    divider: Color(0xFF332C4D),
    success: Color(0xFF03DAC6),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFCF6679),
    navInactive: Color(0xFF7C71A0),
    isDark: true,
  );

  // ── Dark: espresso brown, caramel accent ───────────────────────────────────
  static const NekoPalette chocolateBrown = NekoPalette(
    id: 'chocolateBrown',
    label: 'Havana Espresso',
    emoji: '☕',
    primary: Color(0xFFE0A969),
    primaryDark: Color(0xFFB07B3C),
    primaryLight: Color(0xFF3A2A1B),
    secondary: Color(0xFFFF8A65),
    surface: Color(0xFF291E18),
    surfaceElevated: Color(0xFF352720),
    background: Color(0xFF1B1310),
    inputFill: Color(0xFF332620),
    textPrimary: Color(0xFFF3E7DA),
    textSecondary: Color(0xFFCBB29F),
    textTertiary: Color(0xFF99826F),
    textOnPrimary: Color(0xFF2A1A0C),
    divider: Color(0xFF42332A),
    success: Color(0xFF7CC47F),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFE57373),
    navInactive: Color(0xFF806A58),
    isDark: true,
  );

  // ── Dark: tuxedo charcoal, white tie, coral bowtie ─────────────────────────
  static const NekoPalette tuxedo = NekoPalette(
    id: 'tuxedo',
    label: 'Tuxedo Club',
    emoji: '🎩',
    primary: Color(0xFFF5F5F5),
    primaryDark: Color(0xFFBDBDBD),
    primaryLight: Color(0xFF2A2E36),
    secondary: Color(0xFFFF6B6B),
    surface: Color(0xFF20232B),
    surfaceElevated: Color(0xFF2A2E37),
    background: Color(0xFF14161B),
    inputFill: Color(0xFF272B34),
    textPrimary: Color(0xFFECEEF2),
    textSecondary: Color(0xFFB4B8C2),
    textTertiary: Color(0xFF7E8390),
    textOnPrimary: Color(0xFF15171C),
    divider: Color(0xFF333741),
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFEF5350),
    navInactive: Color(0xFF6C7079),
    isDark: true,
  );

  /// All themes, in display order (warm lights, cool lights, then darks).
  static const List<NekoPalette> all = <NekoPalette>[
    gingerTabby,
    creamBeige,
    tortoiseshell,
    calico,
    sealPoint,
    snowWhite,
    russianBlue,
    silverTabby,
    lilacLavender,
    midnightBlack,
    chocolateBrown,
    tuxedo,
  ];

  /// Returns the palette for [id], or [gingerTabby] if unknown.
  static NekoPalette byId(String? id) {
    for (final NekoPalette p in all) {
      if (p.id == id) return p;
    }
    return gingerTabby;
  }
}
