import 'package:flutter/widgets.dart';

/// A full colour theme derived from a real cat coat. Every per-theme colour the
/// app needs lives here; [AppColors] reads the active palette, so swapping it
/// re-skins the whole app (light or dark).
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

  /// Foreground on top of [primary] (passes 4.5:1).
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

  /// The cat-profile pill banner. A deep on-brand fill that white text sits on.
  Color get banner => isDark ? surfaceElevated : textPrimary;

  /// Tint of the drifting paw pattern (drawn at low opacity).
  Color get pawPattern => primary;
}

/// The twelve cat-coat themes. [gingerTabby] is the default.
abstract final class NekoPalettes {
  const NekoPalettes._();

  static const NekoPalette gingerTabby = NekoPalette(
    id: 'gingerTabby',
    label: 'Ginger Tabby',
    emoji: '🟠',
    primary: Color(0xFFFF6B35),
    primaryDark: Color(0xFFC94F1B),
    primaryLight: Color(0xFFFFF0E6),
    secondary: Color(0xFFFFB347),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFF9F5),
    background: Color(0xFFFFF5EE),
    inputFill: Color(0xFFFFF0E6),
    textPrimary: Color(0xFF2D1506),
    textSecondary: Color(0xFF7A4030),
    textTertiary: Color(0xFFB06845),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFFFD5BC),
    success: Color(0xFF43A047),
    warning: Color(0xFFFB8C00),
    error: Color(0xFFE53935),
    navInactive: Color(0xFFC4A090),
    isDark: false,
  );

  static const NekoPalette midnightBlack = NekoPalette(
    id: 'midnightBlack',
    label: 'Midnight Black',
    emoji: '⚫',
    primary: Color(0xFFBB86FC),
    primaryDark: Color(0xFF7B3FBF),
    primaryLight: Color(0xFF1E0D3B),
    secondary: Color(0xFF03DAC6),
    surface: Color(0xFF1F1B2E),
    surfaceElevated: Color(0xFF2A2542),
    background: Color(0xFF121019),
    inputFill: Color(0xFF2A2542),
    textPrimary: Color(0xFFEDE8FF),
    textSecondary: Color(0xFFA89EC9),
    textTertiary: Color(0xFF6B5F8A),
    textOnPrimary: Color(0xFF000000),
    divider: Color(0xFF302A4A),
    success: Color(0xFF03DAC6),
    warning: Color(0xFFFFB347),
    error: Color(0xFFCF6679),
    navInactive: Color(0xFF4A4060),
    isDark: true,
  );

  static const NekoPalette snowWhite = NekoPalette(
    id: 'snowWhite',
    label: 'Snow White',
    emoji: '🤍',
    primary: Color(0xFF8B9BF8),
    primaryDark: Color(0xFF5A6BD6),
    primaryLight: Color(0xFFE8EBFF),
    secondary: Color(0xFFF4A0C0),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFAFBFF),
    background: Color(0xFFF7F8FF),
    inputFill: Color(0xFFF0F2FF),
    textPrimary: Color(0xFF1A1B2E),
    textSecondary: Color(0xFF5A5C7A),
    textTertiary: Color(0xFF9496B0),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFE0E2FF),
    success: Color(0xFF2E9E6B),
    warning: Color(0xFFF4A100),
    error: Color(0xFFE5484D),
    navInactive: Color(0xFFBFC1D4),
    isDark: false,
  );

  static const NekoPalette russianBlue = NekoPalette(
    id: 'russianBlue',
    label: 'Russian Blue',
    emoji: '🔵',
    primary: Color(0xFF5C7E94),
    primaryDark: Color(0xFF35525E),
    primaryLight: Color(0xFFECEFF1),
    secondary: Color(0xFF80CBC4),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF5F7F8),
    background: Color(0xFFEEF3F6),
    inputFill: Color(0xFFE5EAED),
    textPrimary: Color(0xFF1B2C35),
    textSecondary: Color(0xFF445A68),
    textTertiary: Color(0xFF78909C),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFCFD8DC),
    success: Color(0xFF26A69A),
    warning: Color(0xFFFFA726),
    error: Color(0xFFEF5350),
    navInactive: Color(0xFFB0BEC5),
    isDark: false,
  );

  static const NekoPalette creamBeige = NekoPalette(
    id: 'creamBeige',
    label: 'Cream & Honey',
    emoji: '🍯',
    primary: Color(0xFFE8A838),
    primaryDark: Color(0xFFB07820),
    primaryLight: Color(0xFFFFF8E7),
    secondary: Color(0xFFF4845F),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFDF7),
    background: Color(0xFFFFFBF0),
    inputFill: Color(0xFFFFF8E7),
    textPrimary: Color(0xFF2C1A00),
    textSecondary: Color(0xFF6B4A10),
    textTertiary: Color(0xFFA07830),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFFFE9B8),
    success: Color(0xFF5CB85C),
    warning: Color(0xFFE8A838),
    error: Color(0xFFE55353),
    navInactive: Color(0xFFC9A868),
    isDark: false,
  );

  static const NekoPalette calico = NekoPalette(
    id: 'calico',
    label: 'Calico Carnival',
    emoji: '🎨',
    primary: Color(0xFFF15A29),
    primaryDark: Color(0xFFC0350C),
    primaryLight: Color(0xFFFFF0E8),
    secondary: Color(0xFF6C3483),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFF9F7),
    background: Color(0xFFFFF7F3),
    inputFill: Color(0xFFFFECE4),
    textPrimary: Color(0xFF2A0A00),
    textSecondary: Color(0xFF6B2A00),
    textTertiary: Color(0xFFA05040),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFFFD5C2),
    success: Color(0xFF43A047),
    warning: Color(0xFFFFA000),
    error: Color(0xFFD32F2F),
    navInactive: Color(0xFFC4907A),
    isDark: false,
  );

  static const NekoPalette tortoiseshell = NekoPalette(
    id: 'tortoiseshell',
    label: 'Tortoiseshell',
    emoji: '🍂',
    primary: Color(0xFFC0632A),
    primaryDark: Color(0xFF7B3512),
    primaryLight: Color(0xFFFFF3EA),
    secondary: Color(0xFFD4A017),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFEFAF7),
    background: Color(0xFFFBF3EC),
    inputFill: Color(0xFFF5E9DC),
    textPrimary: Color(0xFF2A1006),
    textSecondary: Color(0xFF5C2E0E),
    textTertiary: Color(0xFF8B4A20),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFEAD0B8),
    success: Color(0xFF388E3C),
    warning: Color(0xFFF57F17),
    error: Color(0xFFC62828),
    navInactive: Color(0xFFB08060),
    isDark: false,
  );

  static const NekoPalette sealPoint = NekoPalette(
    id: 'sealPoint',
    label: 'Siamese Dreams',
    emoji: '👑',
    primary: Color(0xFF6D4C41),
    primaryDark: Color(0xFF3E2723),
    primaryLight: Color(0xFFEFEBE9),
    secondary: Color(0xFF90A4AE),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFF8F6),
    background: Color(0xFFFDF8F5),
    inputFill: Color(0xFFF5EDE8),
    textPrimary: Color(0xFF1C0A00),
    textSecondary: Color(0xFF4E342E),
    textTertiary: Color(0xFF795548),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFD7CCC8),
    success: Color(0xFF43A047),
    warning: Color(0xFFF9A825),
    error: Color(0xFFB71C1C),
    navInactive: Color(0xFFA1887F),
    isDark: false,
  );

  static const NekoPalette chocolateBrown = NekoPalette(
    id: 'chocolateBrown',
    label: 'Havana Espresso',
    emoji: '☕',
    primary: Color(0xFF5D4037),
    primaryDark: Color(0xFF321911),
    primaryLight: Color(0xFFEFEBE9),
    secondary: Color(0xFFFF8A65),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFEFCFA),
    background: Color(0xFFF9F3EE),
    inputFill: Color(0xFFF1E6DD),
    textPrimary: Color(0xFF1A0A00),
    textSecondary: Color(0xFF4A2C1E),
    textTertiary: Color(0xFF795548),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFD7B8A8),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFF8F00),
    error: Color(0xFFE53935),
    navInactive: Color(0xFFA1887F),
    isDark: false,
  );

  static const NekoPalette silverTabby = NekoPalette(
    id: 'silverTabby',
    label: 'Silver Chinchilla',
    emoji: '✨',
    primary: Color(0xFF5C7A8C),
    primaryDark: Color(0xFF34545E),
    primaryLight: Color(0xFFEEF3F6),
    secondary: Color(0xFF4CAF83),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF5F7F9),
    background: Color(0xFFEEF2F5),
    inputFill: Color(0xFFE8EDF2),
    textPrimary: Color(0xFF1A2A35),
    textSecondary: Color(0xFF445A68),
    textTertiary: Color(0xFF7B9BAC),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFC4D0D8),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFFA726),
    error: Color(0xFFE53935),
    navInactive: Color(0xFF9BB0BC),
    isDark: false,
  );

  static const NekoPalette lilacLavender = NekoPalette(
    id: 'lilacLavender',
    label: 'Lilac Whisper',
    emoji: '💜',
    primary: Color(0xFF9575CD),
    primaryDark: Color(0xFF6239A8),
    primaryLight: Color(0xFFF3EEFF),
    secondary: Color(0xFFF48FB1),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFDF9FF),
    background: Color(0xFFF8F5FF),
    inputFill: Color(0xFFF0EBFF),
    textPrimary: Color(0xFF1A0D35),
    textSecondary: Color(0xFF52407A),
    textTertiary: Color(0xFF8B76B8),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFDDD3F5),
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFA726),
    error: Color(0xFFEF5350),
    navInactive: Color(0xFFC3B1E1),
    isDark: false,
  );

  static const NekoPalette tuxedo = NekoPalette(
    id: 'tuxedo',
    label: 'Tuxedo Club',
    emoji: '🎩',
    primary: Color(0xFF212121),
    primaryDark: Color(0xFF000000),
    primaryLight: Color(0xFFF5F5F5),
    secondary: Color(0xFFFF6B6B),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFAFAFA),
    background: Color(0xFFF5F5F5),
    inputFill: Color(0xFFEEEEEE),
    textPrimary: Color(0xFF121212),
    textSecondary: Color(0xFF424242),
    textTertiary: Color(0xFF757575),
    textOnPrimary: Color(0xFFFFFFFF),
    divider: Color(0xFFE0E0E0),
    success: Color(0xFF43A047),
    warning: Color(0xFFFFB300),
    error: Color(0xFFE53935),
    navInactive: Color(0xFF9E9E9E),
    isDark: false,
  );

  /// All themes, in display order.
  static const List<NekoPalette> all = <NekoPalette>[
    gingerTabby,
    midnightBlack,
    snowWhite,
    russianBlue,
    creamBeige,
    calico,
    tortoiseshell,
    sealPoint,
    chocolateBrown,
    silverTabby,
    lilacLavender,
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
