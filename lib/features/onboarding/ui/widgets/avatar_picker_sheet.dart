import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/services/feedback_service.dart';
import '../../data/avatar_presets.dart';
import '../../providers/onboarding_provider.dart';

/// A bottom sheet that lets the user pick a bundled cat avatar instead of
/// uploading a photo. Selecting one stores the preset on the draft and closes.
class AvatarPickerSheet extends ConsumerWidget {
  const AvatarPickerSheet({super.key});

  /// Shows the picker as a tall modal sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AvatarPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? selected = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.avatarPreset),
    );

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Pick an avatar', style: AppTextStyles.headlineLarge),
            const SizedBox(height: 4),
            Text(
              'Choose a look for now — you can change it later.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                ),
                itemCount: AvatarPresets.ids.length,
                itemBuilder: (context, index) {
                  final String id = AvatarPresets.ids[index];
                  return _AvatarTile(
                    id: id,
                    index: index,
                    selected: selected == id,
                    onTap: () {
                      unawaited(ref.read(feedbackServiceProvider).onSelect());
                      ref
                          .read(onboardingNotifierProvider.notifier)
                          .setAvatarPreset(id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.id,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = _tintFor(index);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Avatar ${index + 1}',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
          padding: const EdgeInsets.all(3),
          child: ClipOval(
            child: Image.asset(
              AvatarPresets.assetFor(id),
              fit: BoxFit.cover,
              cacheWidth: 240,
              cacheHeight: 240,
              errorBuilder: (_, _, _) => Container(
                color: tint,
                child: const Icon(
                  Icons.pets_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _tintFor(int index) {
    const List<Color> tints = <Color>[
      Color(0xFFFF8C42),
      Color(0xFF8B7355),
      Color(0xFF9E9E9E),
      Color(0xFFC8A882),
      Color(0xFF6B8E9E),
      Color(0xFFB8651B),
    ];
    return tints[index % tints.length];
  }
}
