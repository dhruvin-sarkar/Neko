import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/neko_palette.dart';
import '../../onboarding/data/onboarding_persistence.dart';

/// SharedPreferences key for the chosen colour theme.
const String _kThemeKey = 'app_theme_palette';

/// Holds the active colour theme and persists the choice on-device.
///
/// Keeps [AppColors.palette] in sync so every widget that reads the brand
/// colours (`AppColors.primary`, etc.) renders in the selected theme. Widgets
/// watch this provider to rebuild when the theme changes.
final themeControllerProvider = NotifierProvider<ThemeController, NekoPalette>(
  ThemeController.new,
);

class ThemeController extends Notifier<NekoPalette> {
  @override
  NekoPalette build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final NekoPalette palette = NekoPalettes.byId(prefs.getString(_kThemeKey));
    // Apply immediately so the very first frame uses the saved theme.
    AppColors.palette = palette;
    return palette;
  }

  /// Switches to [palette] and persists it.
  Future<void> select(NekoPalette palette) async {
    if (palette.id == state.id) return;
    AppColors.palette = palette;
    state = palette;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_kThemeKey, palette.id);
  }
}
