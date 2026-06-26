/// Spacing on a strict 4px grid. I only ever use these values for padding and
/// gaps — no stray 5s, 7s, or 13s.
abstract final class AppSpacing {
  const AppSpacing._();

  static const double x4 = 4;
  static const double x8 = 8;
  static const double x12 = 12;
  static const double x16 = 16; // default screen edge padding
  static const double x20 = 20;
  static const double x24 = 24; // card internal padding
  static const double x32 = 32; // gap between sections
  static const double x40 = 40;
  static const double x48 = 48;
  static const double x64 = 64;
}

/// Corner radii. Nothing in the app is ever fully square — the smallest radius
/// I use is [sm].
abstract final class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12; // inputs, cards, chips
  static const double lg = 16; // buttons
  static const double xl = 24; // bottom sheets
  static const double pill = 100; // full pills
}
