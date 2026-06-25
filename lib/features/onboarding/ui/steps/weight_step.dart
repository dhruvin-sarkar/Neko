import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/widgets/neko_text_field.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/step_headline.dart';

/// Step 4 — the cat's weight in kilograms.
class WeightStep extends ConsumerStatefulWidget {
  const WeightStep({super.key});

  @override
  ConsumerState<WeightStep> createState() => _WeightStepState();
}

class _WeightStepState extends ConsumerState<WeightStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final double? weight = ref.read(onboardingNotifierProvider).draft.weightKg;
    _controller = TextEditingController(
      text: (weight != null && weight > 0) ? '$weight' : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String name = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.name),
    );
    final String display = name.trim().isEmpty ? 'your cat' : name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('How much does $display weigh?'),
        const SizedBox(height: 28),
        NekoTextField(
          controller: _controller,
          hint: '4.5',
          suffixText: 'kg',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: (value) => ref
              .read(onboardingNotifierProvider.notifier)
              .setWeight(double.tryParse(value)),
        ),
        const SizedBox(height: 10),
        Text(
          'An estimate is completely fine.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
