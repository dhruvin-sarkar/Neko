import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/motion/staggered_entrance.dart';
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
    final String display = name.trim().isEmpty ? 'your cat' : name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('What breed is $display?'),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: OnboardingOptions.breeds.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final String breed = OnboardingOptions.breeds[index];
              return StaggeredEntrance(
                delay: Duration(milliseconds: 60 * index),
                child: ChoiceCard(
                  label: breed,
                  isSelected: selected == breed,
                  onTap: () => notifier.setBreed(breed),
                  leading: const _BreedDot(),
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
