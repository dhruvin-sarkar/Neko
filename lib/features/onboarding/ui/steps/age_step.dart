import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/step_headline.dart';

/// Step 3 — the cat's age in years and/or months, with an optional birthday.
class AgeStep extends ConsumerStatefulWidget {
  const AgeStep({super.key});

  @override
  ConsumerState<AgeStep> createState() => _AgeStepState();
}

class _AgeStepState extends ConsumerState<AgeStep> {
  late final TextEditingController _years;
  late final TextEditingController _months;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingNotifierProvider).draft;
    _years = TextEditingController(
      text: draft.ageYears > 0 ? '${draft.ageYears}' : '',
    );
    _months = TextEditingController(
      text: draft.ageMonths > 0 ? '${draft.ageMonths}' : '',
    );
  }

  @override
  void dispose() {
    _years.dispose();
    _months.dispose();
    super.dispose();
  }

  void _update() {
    ref
        .read(onboardingNotifierProvider.notifier)
        .setAge(
          years: int.tryParse(_years.text) ?? 0,
          months: int.tryParse(_months.text) ?? 0,
        );
  }

  Future<void> _pickBirthday() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(onboardingNotifierProvider).draft.birthday ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (picked != null) {
      ref.read(onboardingNotifierProvider.notifier).setBirthday(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.name),
    );
    final DateTime? birthday = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.birthday),
    );
    final String display = name.trim().isEmpty ? 'your cat' : name.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('How old is $display?'),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _AgeField(
                label: 'Years',
                controller: _years,
                onChanged: _update,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _AgeField(
                label: 'Months',
                controller: _months,
                onChanged: _update,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (birthday == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickBirthday,
              icon: const Icon(
                Icons.cake_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(
                'Add birthday',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: _BirthdayChip(
              date: birthday,
              onRemove: () => ref
                  .read(onboardingNotifierProvider.notifier)
                  .setBirthday(null),
            ),
          ),
      ],
    );
  }
}

class _AgeField extends StatelessWidget {
  const _AgeField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: AppTextStyles.bodyLarge,
      cursorColor: AppColors.primary,
      maxLength: 2,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(labelText: label, counterText: ''),
    );
  }
}

class _BirthdayChip extends StatelessWidget {
  const _BirthdayChip({required this.date, required this.onRemove});

  final DateTime date;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final String label =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.selectedFill,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.selectedBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
