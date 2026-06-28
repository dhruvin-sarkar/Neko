import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/neko_motion.dart';
import '../../../../shared/services/feedback_service.dart';
import '../../data/onboarding_options.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/step_headline.dart';

/// Step 6 — the activity level. The final question before saving.
class ActivityStep extends ConsumerWidget {
  const ActivityStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String name = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.name),
    );
    final String? selected = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.activityLevel),
    );
    final notifier = ref.read(onboardingNotifierProvider.notifier);
    final FeedbackService feedback = ref.read(feedbackServiceProvider);
    final String display = name.trim().isEmpty ? 'your cat' : name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('How active is $display?'),
        const SizedBox(height: 24),
        for (int i = 0; i < OnboardingOptions.activities.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          ActivityCard(
                option: OnboardingOptions.activities[i],
                isSelected: selected == OnboardingOptions.activities[i].value,
                onTap: () {
                  unawaited(feedback.onSelect());
                  notifier.setActivityLevel(
                    OnboardingOptions.activities[i].value,
                  );
                },
              )
              .animate(delay: (60 * i).ms)
              .fadeIn(duration: NekoMotion.base)
              .slideY(
                begin: 0.3,
                end: 0,
                duration: NekoMotion.entry,
                curve: Curves.easeOutCubic,
              ),
        ],
      ],
    );
  }
}
