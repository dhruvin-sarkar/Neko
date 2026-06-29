import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../app/app_info.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/neko_palette.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/neko_motion.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../shared/motion/page_transitions.dart';
import '../../../shared/services/feedback_service.dart';
import '../../../shared/widgets/neko_dialog.dart';
import '../../../core/widgets/neko_button.dart';
import '../../../shared/widgets/neko_snackbar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/sound_settings_controller.dart';
import '../providers/theme_controller.dart';

/// The Settings tab. Background and bottom nav pill are provided by [MainShell].
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    unawaited(ref.read(feedbackServiceProvider).onTap());
    final bool? confirmed = await showNekoDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Sign out?', style: AppTextStyles.headlineLarge),
        content: Text(
          'You can always sign back in with your account.',
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
              'Sign out',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Hand off with the branded paw curtain: it sweeps closed over Settings,
    // holds at full cover while we sign out AND wait for the auth state to
    // clear (so the router has swapped to Welcome underneath), then sweeps open
    // to reveal Welcome. Holding until the swap is done is what stops the old
    // screen flashing during the reveal.
    final authController = ref.read(authControllerProvider.notifier);
    final auth = ref.read(firebaseAuthProvider);
    unawaited(ref.read(feedbackServiceProvider).onAdvance());
    await playPawCurtain(
      context,
      instantCover: true,
      onCovered: () async {
        await authController.signOut();
        // Wait (up to ~640ms) for sign-out to propagate so Welcome is in place.
        for (int i = 0; i < 40 && auth.currentUser != null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
        // Brief settle so the router finishes redirecting to Welcome before the
        // curtain opens onto it.
        await Future<void>.delayed(const Duration(milliseconds: 90));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surface a failed sign-out (e.g. no network) instead of silently doing
    // nothing. A success flows through authStateChanges → router redirect.
    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        final Object error = next.error;
        NekoSnackBar.show(
          context,
          error is AppException ? error.message : 'Something went wrong.',
          error: true,
        );
      }
    });

    final bool isLoading = ref.watch(
      authControllerProvider.select((s) => s.isLoading),
    );
    final user = ref.watch(authStateChangesProvider).valueOrNull;
    final String? displayName = user?.displayName;
    final String? email = user?.email;
    // Rebuild Settings (and re-skin it) when the colour theme changes.
    ref.watch(themeControllerProvider);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child:
            Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Settings',
                            style: AppTextStyles.displayLarge,
                          ),
                        ),
                        RepaintBoundary(
                          child: Lottie.asset(
                            'assets/animations/rainbow_cat.json',
                            width: 104,
                            height: 64,
                            fit: BoxFit.contain,
                            repeat: !MediaQuery.disableAnimationsOf(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _AccountCard(
                              displayName: displayName,
                              email: email,
                            ),
                            const SizedBox(height: 16),
                            const _ThemeCard(),
                            const SizedBox(height: 16),
                            const _SoundCard(),
                            const SizedBox(height: 16),
                            const _AboutCard(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    NekoButton.primary(
                      label: 'Sign out',
                      isLoading: isLoading,
                      onPressed: () => _confirmSignOut(context, ref),
                    ),
                  ],
                )
                .animate()
                .fadeIn(duration: NekoMotion.entry)
                .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

/// The theme picker: a card of colour-scheme swatches the user can switch
/// between. The active theme is ringed and checked.
class _ThemeCard extends ConsumerWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NekoPalette current = ref.watch(themeControllerProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.selectedFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.palette_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme', style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(current.label, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final NekoPalette p in NekoPalettes.all)
                _ThemeSwatch(
                  palette: p,
                  selected: p.id == current.id,
                  onTap: () {
                    unawaited(ref.read(feedbackServiceProvider).onSelect());
                    ref.read(themeControllerProvider.notifier).select(p);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A single tappable theme swatch: a circle of the theme's background with its
/// accent dot, ringed + checked when active.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final NekoPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: palette.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: palette.background,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.almostBlack : AppColors.border,
              width: selected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: selected
              ? Icon(Icons.check_rounded, color: palette.primary, size: 24)
              : Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }
}

/// The signed-in user's identity: a monogram avatar, name, and email.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.displayName, required this.email});

  final String? displayName;
  final String? email;

  String get _initial {
    final String source = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : (email?.trim() ?? '');
    return source.isEmpty ? 'N' : source[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : 'Cat parent';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.selectedFill,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initial,
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLarge,
                ),
                if (email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    email!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A small "About" card with the app name, tagline, and version.
class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.selectedFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.pets_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppInfo.name, style: AppTextStyles.bodyLarge),
                const SizedBox(height: 2),
                Text(AppInfo.tagline, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            'v${AppInfo.version}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sound preferences: a master mute toggle plus effects and purring volume.
class _SoundCard extends ConsumerWidget {
  const _SoundCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SoundSettings settings = ref.watch(soundSettingsControllerProvider);
    final SoundSettingsController controller = ref.read(
      soundSettingsControllerProvider.notifier,
    );
    final bool soundOn = !settings.muted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.selectedFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sound', style: AppTextStyles.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      soundOn ? 'Effects & purring on' : 'Muted',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Switch(
                value: soundOn,
                activeThumbColor: AppColors.primary,
                onChanged: (bool enabled) {
                  if (enabled) {
                    controller.setMuted(false);
                    HapticService.selection();
                    unawaited(AudioService.playSound(SoundId.toggle));
                  } else {
                    // Play the toggle before muting, or it would be silenced.
                    unawaited(AudioService.playSound(SoundId.toggle));
                    HapticService.selection();
                    controller.setMuted(true);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _VolumeRow(
            label: 'Effects volume',
            icon: Icons.graphic_eq_rounded,
            value: settings.sfxVolume,
            max: 1,
            enabled: soundOn,
            onChanged: controller.setSfxVolume,
            onChangeEnd: (_) =>
                unawaited(AudioService.playSound(SoundId.btnTapPrimary)),
          ),
          _VolumeRow(
            label: 'Purring volume',
            icon: Icons.pets_rounded,
            value: settings.ambientVolume,
            max: 0.7,
            enabled: soundOn,
            onChanged: controller.setAmbientVolume,
          ),
        ],
      ),
    );
  }
}

/// A labelled slider row used inside [_SoundCard]; dims when sound is muted.
class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.max,
    required this.enabled,
    required this.onChanged,
    this.onChangeEnd,
  });

  final String label;
  final IconData icon;
  final double value;
  final double max;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(width: 96, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: Slider(
              value: value.clamp(0.0, max),
              max: max,
              activeColor: AppColors.primary,
              onChanged: enabled ? onChanged : null,
              onChangeEnd: enabled ? onChangeEnd : null,
            ),
          ),
        ],
      ),
    );
  }
}
