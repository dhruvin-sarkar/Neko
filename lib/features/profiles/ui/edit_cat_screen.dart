import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/widgets/neko_primary_button.dart';
import '../../../shared/widgets/neko_text_field.dart';
import '../../onboarding/data/calorie_calculator.dart';
import '../../onboarding/data/onboarding_options.dart';
import '../../onboarding/models/cat_profile.dart';
import '../providers/profile_edit_controller.dart';
import '../providers/profile_provider.dart';

/// Edit a cat's onboarding details. Pre-filled from the live profile; saves via
/// [ProfileEditController] and recomputes the daily calorie target.
class EditCatScreen extends ConsumerStatefulWidget {
  const EditCatScreen({super.key, required this.catId});

  final String catId;

  @override
  ConsumerState<EditCatScreen> createState() => _EditCatScreenState();
}

class _EditCatScreenState extends ConsumerState<EditCatScreen> {
  CatProfile? _original;
  late final TextEditingController _name;
  late final TextEditingController _years;
  late final TextEditingController _months;
  late final TextEditingController _weight;

  // Ephemeral edit-form selections (see DECISIONS.md).
  String? _breed;
  String? _coat;
  String? _activity;

  @override
  void initState() {
    super.initState();
    final CatProfile? cat = ref.read(catByIdProvider(widget.catId));
    _original = cat;
    _name = TextEditingController(text: cat?.name ?? '');
    _years = TextEditingController(
      text: (cat != null && cat.years > 0) ? '${cat.years}' : '',
    );
    _months = TextEditingController(
      text: (cat != null && cat.months > 0) ? '${cat.months}' : '',
    );
    _weight = TextEditingController(
      text: (cat != null && cat.weightKg > 0) ? '${cat.weightKg}' : '',
    );
    _breed = cat?.breed;
    _coat = cat?.colorType;
    _activity = cat?.activityLevel;
  }

  @override
  void dispose() {
    _name.dispose();
    _years.dispose();
    _months.dispose();
    _weight.dispose();
    super.dispose();
  }

  bool get _isValid {
    final String name = _name.text.trim();
    final int years = int.tryParse(_years.text) ?? 0;
    final int months = int.tryParse(_months.text) ?? 0;
    final double weight = double.tryParse(_weight.text) ?? 0;
    return name.isNotEmpty &&
        name.length <= 50 &&
        _breed != null &&
        (years > 0 || months > 0) &&
        weight > 0 &&
        weight <= 30 &&
        _coat != null &&
        _activity != null;
  }

  Future<void> _save() async {
    final CatProfile? original = _original;
    if (original == null || !_isValid) return;
    final int years = int.tryParse(_years.text) ?? 0;
    final int months = int.tryParse(_months.text) ?? 0;
    final double weight = double.tryParse(_weight.text) ?? 0;
    final String activity = _activity ?? original.activityLevel;

    final CatProfile updated = original.copyWith(
      name: _name.text.trim(),
      breed: _breed ?? original.breed,
      ageMonths: years * 12 + months,
      weightKg: weight,
      colorType: _coat ?? original.colorType,
      activityLevel: activity,
      dailyCalorieTarget: CalorieCalculator.dailyTarget(
        weightKg: weight,
        activity: activity,
      ),
    );

    unawaited(ref.read(feedbackServiceProvider).onTap());
    final bool ok = await ref
        .read(profileEditControllerProvider.notifier)
        .save(updated);
    if (ok && mounted) {
      unawaited(ref.read(feedbackServiceProvider).onSuccess());
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(profileEditControllerProvider, (
      previous,
      next,
    ) {
      if (next is AsyncError) {
        final Object error = next.error;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                error is AppException ? error.message : 'Something went wrong.',
              ),
            ),
          );
      }
    });

    final bool isSaving = ref.watch(
      profileEditControllerProvider.select((s) => s.isLoading),
    );

    if (_original == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(leading: const BackButton()),
        body: Center(
          child: Text(
            "We can't find that cat to edit.",
            style: AppTextStyles.headlineLarge,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          'Edit ${_name.text.trim()}',
          style: AppTextStyles.headlineLarge,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            NekoTextField(
              label: 'Name',
              controller: _name,
              maxLength: 50,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _Dropdown(
              label: 'Breed',
              value: _breed,
              items: OnboardingOptions.breeds
                  .map(
                    (b) => DropdownMenuItem<String>(value: b, child: Text(b)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _breed = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NekoTextField(
                    label: 'Years',
                    controller: _years,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    showValidCheck: false,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: NekoTextField(
                    label: 'Months',
                    controller: _months,
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    showValidCheck: false,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            NekoTextField(
              label: 'Weight',
              controller: _weight,
              suffixText: 'kg',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            _Dropdown(
              label: 'Coat',
              value: _coat,
              items: OnboardingOptions.coats
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.value,
                      child: Text(c.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _coat = v),
            ),
            const SizedBox(height: 16),
            _Dropdown(
              label: 'Activity',
              value: _activity,
              items: OnboardingOptions.activities
                  .map(
                    (a) => DropdownMenuItem<String>(
                      value: a.value,
                      child: Text(a.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _activity = v),
            ),
            const SizedBox(height: 32),
            NekoPrimaryButton(
              label: 'Save changes',
              enabled: _isValid,
              isLoading: isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: items,
      onChanged: onChanged,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(labelText: label),
    );
  }
}
