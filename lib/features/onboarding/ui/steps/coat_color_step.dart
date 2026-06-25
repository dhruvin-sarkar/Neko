import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/services/feedback_service.dart';
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
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final FeedbackService feedback = ref.read(feedbackServiceProvider);
    final String display = name.trim().isEmpty ? 'your cat' : name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('What does $display look like?'),
        const SizedBox(height: 20),
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
                    isSelected: selected == option.value,
                    onTap: () {
                      unawaited(feedback.onSelect());
                      notifier.setColorType(option.value);
                    },
                  )
                  .animate(delay: (60 * index).ms)
                  .fadeIn(duration: 250.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0,
                    duration: 280.ms,
                    curve: Curves.easeOutCubic,
                  );
            },
          ),
        ),
      ],
    );
  }
}
