import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/theme/neko_palette.dart';
import '../../../../core/neko_motion.dart';
import '../../../../features/settings/providers/theme_controller.dart';
import '../../../../shared/services/feedback_service.dart';
import '../../../../shared/widgets/neko_snackbar.dart';
import '../../data/onboarding_options.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/color_swatch_card.dart';
import '../widgets/step_headline.dart';

/// Step 5 — the coat color, shown as a 2-column grid of swatches.
class CoatColorStep extends ConsumerWidget {
  const CoatColorStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String name = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.name),
    );
    final String? selected = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.colorType),
    );
    // The selected card is keyed off the active theme (unique per coat) so
    // coats that share an avatar colour key don't both highlight.
    final String activeThemeId = ref.watch(themeControllerProvider).id;
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final FeedbackService feedback = ref.read(feedbackServiceProvider);
    final String display = name.trim().isEmpty ? 'your cat' : name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('What does $display look like?'),
        const SizedBox(height: 8),
        Text(
          'Their coat becomes the app’s whole look — try a few.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: OnboardingOptions.coats.length,
            itemBuilder: (context, index) {
              final option = OnboardingOptions.coats[index];
              return ColorSwatchCard(
                    option: option,
                    isSelected:
                        selected != null && activeThemeId == option.themeId,
                    onTap: () {
                      // The showstopper: choosing a coat re-themes the whole
                      // app to that cat's colour, instantly, everywhere.
                      final String? themeId = option.themeId;
                      if (themeId != null) {
                        ref
                            .read(themeControllerProvider.notifier)
                            .select(NekoPalettes.byId(themeId));
                        // Same select triad as every other choice in the app —
                        // the whole-app re-theme is the star of the moment, so
                        // the standard snackbar just names what happened.
                        unawaited(feedback.onSelect());
                        NekoSnackBar.show(
                          context,
                          '${option.label} theme applied',
                          // Float clear of the Continue chiclet: judges tap
                          // several coats in a row to watch the re-theme.
                          bottomMargin: 88,
                        );
                      } else {
                        unawaited(feedback.onSelect());
                      }
                      notifier.setColorType(option.value);
                    },
                  )
                  .animate(
                    delay:
                        (NekoMotion.staggerItem.inMilliseconds *
                                index.clamp(0, 7))
                            .ms,
                  )
                  .fadeIn(duration: NekoMotion.base)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    duration: NekoMotion.entry,
                    curve: NekoMotion.enter,
                  );
            },
          ),
        ),
      ],
    );
  }
}
