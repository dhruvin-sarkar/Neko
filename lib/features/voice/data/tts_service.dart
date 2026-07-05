import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/utils/logger.dart';

/// Wrapper around `flutter_tts` for reading Hey Neko's answers aloud.
///
/// [speak] resolves when the utterance finishes (or fails), so the caller can
/// advance its state machine — listening → thinking → speaking → done — without
/// polling. A single utterance plays at a time; starting a new one stops the
/// old. We never log the spoken text.
class TtsService {
  TtsService() {
    unawaited(_configure());
  }

  final FlutterTts _tts = FlutterTts();
  Completer<void>? _speaking;

  Future<void> _configure() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      // A touch brighter than default — Neko's voice is playful, not robotic.
      await _tts.setPitch(1.12);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(_finish);
      _tts.setCancelHandler(_finish);
      _tts.setErrorHandler((message) => _finish());
    } on Object catch (e, st) {
      AppLogger.warning('TTS configure failed', e, st);
    }
  }

  void _finish() {
    final Completer<void>? c = _speaking;
    _speaking = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Speaks [text], completing when the utterance ends. No-op for empty text.
  Future<void> speak(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await stop();
    final Completer<void> completer = Completer<void>();
    _speaking = completer;
    try {
      // With awaitSpeakCompletion(true) this resolves when playback ends; the
      // handlers cover platforms where it returns early.
      await _tts.speak(trimmed);
    } on Object catch (e, st) {
      AppLogger.warning('TTS speak failed', e, st);
    }
    _finish();
    return completer.future;
  }

  /// Stops any in-progress speech immediately.
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Object catch (e, st) {
      AppLogger.warning('TTS stop failed', e, st);
    }
    _finish();
  }
}

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());
