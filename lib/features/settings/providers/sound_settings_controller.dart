import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/audio_service.dart';
import '../../onboarding/data/onboarding_persistence.dart';

const String _kMutedKey = 'sound_muted';
const String _kSfxVolumeKey = 'sound_sfx_volume';
const String _kAmbientVolumeKey = 'sound_ambient_volume';

/// The user's sound preferences: master mute, effects volume, and the ambient
/// "purring" volume. Immutable; mutate through [SoundSettingsController].
@immutable
class SoundSettings {
  const SoundSettings({
    required this.muted,
    required this.sfxVolume,
    required this.ambientVolume,
  });

  /// When true, every sound is silenced.
  final bool muted;

  /// One-shot effects volume, 0.0–1.0.
  final double sfxVolume;

  /// Ambient purr volume, 0.0–0.3 (kept low so it stays a background texture).
  final double ambientVolume;

  SoundSettings copyWith({
    bool? muted,
    double? sfxVolume,
    double? ambientVolume,
  }) => SoundSettings(
    muted: muted ?? this.muted,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    ambientVolume: ambientVolume ?? this.ambientVolume,
  );
}

/// Holds the sound preferences, persists them on-device, and keeps the
/// [AudioService] engine in sync. Widgets watch this to rebuild the Settings
/// controls; building it (e.g. once in `main()`) applies the saved values to
/// the engine before the first frame.
final soundSettingsControllerProvider =
    NotifierProvider<SoundSettingsController, SoundSettings>(
      SoundSettingsController.new,
    );

class SoundSettingsController extends Notifier<SoundSettings> {
  @override
  SoundSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final SoundSettings settings = SoundSettings(
      muted: prefs.getBool(_kMutedKey) ?? false,
      sfxVolume: prefs.getDouble(_kSfxVolumeKey) ?? 0.35,
      ambientVolume: prefs.getDouble(_kAmbientVolumeKey) ?? 0.12,
    );
    // Push the saved preference into the engine straight away.
    AudioService.setMuted(settings.muted);
    AudioService.setSfxVolume(settings.sfxVolume);
    AudioService.setAmbientVolume(settings.ambientVolume);
    return settings;
  }

  /// Silences or restores all sound.
  Future<void> setMuted(bool muted) async {
    if (muted == state.muted) return;
    state = state.copyWith(muted: muted);
    AudioService.setMuted(muted);
    await ref.read(sharedPreferencesProvider).setBool(_kMutedKey, muted);
  }

  /// Sets the one-shot effects volume (0.0–1.0).
  Future<void> setSfxVolume(double value) async {
    final double v = value.clamp(0.0, 1.0);
    state = state.copyWith(sfxVolume: v);
    AudioService.setSfxVolume(v);
    await ref.read(sharedPreferencesProvider).setDouble(_kSfxVolumeKey, v);
  }

  /// Sets the ambient purr volume (0.0–0.3).
  Future<void> setAmbientVolume(double value) async {
    final double v = value.clamp(0.0, 0.3);
    state = state.copyWith(ambientVolume: v);
    AudioService.setAmbientVolume(v);
    await ref.read(sharedPreferencesProvider).setDouble(_kAmbientVolumeKey, v);
  }
}
