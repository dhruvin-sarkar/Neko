import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sound_service.dart';

part 'feedback_service.g.dart';

/// Combines haptics and sound into single tactile "moments".
///
/// Callers fire-and-forget these (e.g. `unawaited(feedback.onTap())`) — the UI
/// never blocks on feedback.
class FeedbackService {
  const FeedbackService(this._sound);

  final SoundService _sound;

  /// Light tactile tick for button taps.
  Future<void> onTap() =>
      Future.wait<void>([HapticFeedback.selectionClick(), _sound.tap()]);

  /// Slightly heavier feedback for selecting a choice card.
  Future<void> onSelect() =>
      Future.wait<void>([HapticFeedback.lightImpact(), _sound.select()]);

  /// Celebratory feedback for success moments (auth, onboarding complete).
  Future<void> onSuccess() =>
      Future.wait<void>([HapticFeedback.mediumImpact(), _sound.success()]);
}

/// App-wide [FeedbackService].
@Riverpod(keepAlive: true)
FeedbackService feedbackService(Ref ref) =>
    FeedbackService(ref.watch(soundServiceProvider));
