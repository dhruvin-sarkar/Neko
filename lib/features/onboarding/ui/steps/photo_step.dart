import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../shared/services/feedback_service.dart';
import '../../../../shared/services/image_picker_service.dart';
import '../../data/avatar_presets.dart';
import '../../providers/onboarding_provider.dart';
import '../widgets/avatar_picker_sheet.dart';
import '../widgets/step_headline.dart';

/// Step 2 — an optional cat photo (camera/gallery) or a preset avatar.
class PhotoStep extends ConsumerWidget {
  const PhotoStep({super.key});

  Future<void> _pick(WidgetRef ref, ImageSource source) async {
    unawaited(ref.read(feedbackServiceProvider).onTap());
    final String? path = await ref
        .read(imagePickerServiceProvider)
        .pick(source);
    if (path != null) {
      ref.read(onboardingNotifierProvider.notifier).setPhotoPath(path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String name = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.name),
    );
    final String? photoPath = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.photoPath),
    );
    final String? avatarPreset = ref.watch(
      onboardingNotifierProvider.select((s) => s.draft.avatarPreset),
    );
    final String display = name.trim().isEmpty ? 'your cat' : name.trim();
    final bool hasAvatar = photoPath != null || avatarPreset != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepHeadline('Add a photo of $display'),
        const SizedBox(height: 8),
        Text(
          'Optional — you can always add one later.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        Center(
          child: _PhotoPreview(
            photoPath: photoPath,
            avatarPreset: avatarPreset,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ref, ImageSource.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pick(ref, ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              unawaited(ref.read(feedbackServiceProvider).onTap());
              AvatarPickerSheet.show(context);
            },
            child: Text(
              hasAvatar ? 'Choose a different avatar' : 'Maybe later',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        if (hasAvatar)
          Center(
            child: TextButton(
              onPressed: () => ref
                  .read(onboardingNotifierProvider.notifier)
                  .setPhotoPath(null),
              child: Text(
                'Remove',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photoPath, required this.avatarPreset});

  final String? photoPath;
  final String? avatarPreset;

  @override
  Widget build(BuildContext context) {
    const double size = 160;

    final String? path = photoPath;
    if (path != null) {
      return ClipOval(
        child: Image.file(
          File(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    if (AvatarPresets.isPreset(avatarPreset)) {
      return ClipOval(
        child: Image.asset(
          AvatarPresets.assetFor(avatarPreset ?? ''),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _PlaceholderCircle(size: size),
        ),
      );
    }

    return const _PlaceholderCircle(size: size);
  }
}

class _PlaceholderCircle extends StatelessWidget {
  const _PlaceholderCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.selectedFill,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.pets_rounded, size: 64, color: AppColors.primary),
    );
  }
}
