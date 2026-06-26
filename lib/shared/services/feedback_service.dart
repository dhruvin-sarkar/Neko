import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'sound_service.dart';

part 'feedback_service.g.dart';

/// Pairs a haptic with a sound for each interaction "moment", so every part of
/// the app speaks the same tactile language. Widgets always go through here —
/// they never call [HapticFeedback] or the audio layer directly.
///
/// Callers fire-and-forget these (e.g. `unawaited(feedback.onTap())`) so the
/// UI never waits on feedback.
class FeedbackService {
  const FeedbackService(this._sound);

  final SoundService _sound;

  /// A button tap.
  Future<void> onTap() =>
      Future.wait<void>([HapticFeedback.lightImpact(), _sound.tap()]);

  /// Selecting a choice card.
  Future<void> onSelect() =>
      Future.wait<void>([HapticFeedback.selectionClick(), _sound.select()]);

  /// Advancing to the next step (e.g. the onboarding continue button).
  Future<void> onAdvance() =>
      Future.wait<void>([HapticFeedback.mediumImpact(), _sound.whoosh()]);

  /// A success moment — auth or onboarding complete. The double tap (heavy,
  /// short gap, medium) is what makes a completion feel genuinely rewarding.
  Future<void> onSuccess() async {
    unawaited(_sound.success());
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
  }

  /// An error or failed validation.
  Future<void> onError() =>
      Future.wait<void>([HapticFeedback.vibrate(), _sound.error()]);
}

/// App-wide [FeedbackService].
@Riverpod(keepAlive: true)
FeedbackService feedbackService(Ref ref) =>
    FeedbackService(ref.watch(soundServiceProvider));
