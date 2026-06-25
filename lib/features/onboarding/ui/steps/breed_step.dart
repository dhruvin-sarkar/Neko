import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/services/feedback_service.dart';
import '../../data/onboarding_options.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/choice_card.dart';
import '../widgets/step_headline.dart';

/// Step 2 — the breed, chosen from a scrollable list of cards that cascade in.
class BreedStep extends ConsumerWidget {
  const BreedStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String name = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.name),
    );
    final String? selected = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.breed),
    );
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final FeedbackService feedback = ref.read(feedbackServiceProvider);
    final String display = name.trim().isEmpty ? 'your cat' : name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('What breed is $display?'),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: OnboardingOptions.breeds.length,
            itemBuilder: (context, index) {
              final String breed = OnboardingOptions.breeds[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child:
                    ChoiceCard(
                          label: breed,
                          isSelected: selected == breed,
                          onTap: () {
                            unawaited(feedback.onSelect());
                            notifier.setBreed(breed);
                          },
                          leading: const _BreedDot(),
                        )
                        .animate(delay: (60 * index).ms)
                        .fadeIn(duration: 250.ms)
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 280.ms,
                          curve: Curves.easeOutCubic,
                        ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BreedDot extends StatelessWidget {
  const _BreedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}
