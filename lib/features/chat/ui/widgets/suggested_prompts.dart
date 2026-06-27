import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Starter prompts shown when the conversation is empty. Tapping one drops the
/// question into the composer so the user can edit or send it.
class SuggestedPrompts extends StatelessWidget {
  const SuggestedPrompts({super.key, required this.onSelect});

  final ValueChanged<String> onSelect;

  static const List<(String, String)> _prompts = <(String, String)>[
    ('Daily care', 'How much should my cat eat each day?'),
    ('Health', 'What are signs my cat might be unwell?'),
    ('Playtime', 'Fun ways to keep my cat active indoors'),
    ('New arrival', 'Tips for settling in a new kitten'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (String title, String question) in _prompts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PromptCard(
              title: title,
              question: question,
              onTap: () => onSelect(question),
            ),
          ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.title,
    required this.question,
    required this.onTap,
  });

  final String title;
  final String question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.snowWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                question,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
