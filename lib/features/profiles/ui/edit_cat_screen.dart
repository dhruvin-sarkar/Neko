import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/widgets/neko_dialog.dart';
import '../../../shared/widgets/neko_primary_button.dart';
import '../../../shared/widgets/neko_snackbar.dart';
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
  bool _initialized = false;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _years = TextEditingController();
  final TextEditingController _months = TextEditingController();
  final TextEditingController _weight = TextEditingController();

  // I hold the dropdown selections here while the form is open.
  String? _breed;
  String? _coat;
  String? _activity;

  /// Fills the form from [cat] exactly once, the moment the profile becomes
  /// available. Reaching this screen before the cat list has loaded (e.g. a
  /// deep link or a hot restart on the edit route) therefore recovers instead
  /// of stranding the user.
  void _initFrom(CatProfile cat) {
    if (_initialized) return;
    _initialized = true;
    _original = cat;
    _name.text = cat.name;
    _years.text = cat.years > 0 ? '${cat.years}' : '';
    _months.text = cat.months > 0 ? '${cat.months}' : '';
    _weight.text = cat.weightKg > 0 ? '${cat.weightKg}' : '';
    _breed = cat.breed;
    _coat = cat.colorType;
    _activity = cat.activityLevel;
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

  Future<void> _delete() async {
    final CatProfile? original = _original;
    if (original == null) return;

    unawaited(ref.read(feedbackServiceProvider).onTap());
    final bool? confirmed = await showNekoDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Remove ${original.name}?',
          style: AppTextStyles.headlineLarge,
        ),
        content: Text(
          "This deletes ${original.name}'s profile and all their documents. "
          "This can't be undone.",
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Remove',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final bool ok = await ref
        .read(profileEditControllerProvider.notifier)
        .delete(original.id);
    if (ok && mounted) {
      unawaited(ref.read(feedbackServiceProvider).onSuccess());
      // The cat no longer exists, so return to Home rather than its (now
      // missing) detail screen.
      context.go(Routes.home);
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
        NekoSnackBar.show(
          context,
          error is AppException ? error.message : 'Something went wrong.',
          error: true,
        );
      }
    });

    final bool isSaving = ref.watch(
      profileEditControllerProvider.select((s) => s.isLoading),
    );

    // Resolve the cat reactively so the form fills in as soon as the profile
    // list has loaded, even if this screen opened first.
    final CatProfile? cat = ref.watch(catByIdProvider(widget.catId));
    if (cat != null) _initFrom(cat);
    final bool stillLoading = ref.watch(
      catProfilesProvider.select((v) => v.isLoading),
    );

    if (_original == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(leading: const BackButton(color: AppColors.textPrimary)),
        body: Center(
          child: (cat == null && stillLoading)
              ? CircularProgressIndicator(color: AppColors.primary)
              : Text(
                  "We can't find that cat to edit.",
                  style: AppTextStyles.headlineLarge,
                ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: isSaving ? null : _delete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.primaryDark,
                  size: 20,
                ),
                label: Text(
                  'Remove this cat',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
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
