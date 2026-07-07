import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/utils/logger.dart';

/// Thin wrapper around `speech_to_text` for the Hey Neko tap-to-talk flow.
///
/// One lazily-initialised recogniser. `speech_to_text.initialize()` also drives
/// the platform RECORD_AUDIO permission prompt, so a false return from
/// [ensureReady] means either the plugin is unavailable or the microphone was
/// denied — callers treat both the same way (fall back to typing). We never log
/// recognised words: transcripts stay on-device and out of the logs.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialised = false;

  // speech_to_text keeps ONE status/error listener, set once at initialize().
  // Two callers share this service (the wake loop and the command session), so
  // we register stable trampolines at init and re-point these to whoever called
  // ensureReady most recently — the controller that currently owns the mic.
  // Without this, the second caller's status/error events are silently dropped.
  void Function(String status)? _statusCb;
  void Function(String error)? _errorCb;

  bool get isListening => _speech.isListening;

  /// Initialises recognition (and requests the mic permission on first call).
  /// Returns whether speech is available to use right now.
  Future<bool> ensureReady({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    // Always adopt the current caller's callbacks, even when already
    // initialised — this is what makes status/error route to the right owner.
    _statusCb = onStatus;
    _errorCb = onError;
    if (_initialised && _speech.isAvailable) return true;
    try {
      _initialised = await _speech.initialize(
        onStatus: (String s) => _statusCb?.call(s),
        onError: (SpeechRecognitionError e) => _errorCb?.call(e.errorMsg),
        debugLogging: false,
      );
      if (_initialised) await _resolveEnglishLocale();
    } on Object catch (e, st) {
      AppLogger.warning('Speech recognition init failed', e, st);
      _initialised = false;
    }
    return _initialised;
  }

  /// The device's English recogniser locale, if one is installed. The wake word
  /// ("Neko") is an English sound and recognises far more reliably under en-*
  /// than under a non-English default locale — so the wake loop pins this while
  /// the command session stays on the user's system language.
  String? _englishLocaleId;
  Future<void> _resolveEnglishLocale() async {
    if (_englishLocaleId != null) return;
    try {
      final List<LocaleName> locales = await _speech.locales();
      for (final LocaleName l in locales) {
        final String id = l.localeId.toLowerCase().replaceAll('-', '_');
        if (id == 'en_us') {
          _englishLocaleId = l.localeId;
          return;
        }
        _englishLocaleId ??= id.startsWith('en') ? l.localeId : null;
      }
    } on Object {
      // No locale list available — fall back to the system default (null).
    }
  }

  /// Starts a listening session. [onWords] fires repeatedly with the running
  /// transcript; [onFinal] fires once with the settled transcript. [onLevel]
  /// reports the mic loudness (0..~10) for the live waveform.
  Future<void> listen({
    required void Function(String words) onWords,
    required void Function(String words) onFinal,
    void Function(double level)? onLevel,
    // The wake loop passes a longer pause so it holds the mic through silence
    // rather than stopping and restarting every few seconds (which flickers the
    // mic indicator and churns audio focus).
    Duration pauseFor = const Duration(seconds: 3),
    Duration listenFor = const Duration(seconds: 30),
    // The wake loop sets this so "Neko" is recognised under English phonetics
    // regardless of the device's default locale. The command session leaves it
    // off so questions can be asked in the user's own language.
    bool preferEnglish = false,
  }) async {
    await _speech.listen(
      onResult: (SpeechRecognitionResult r) {
        onWords(r.recognizedWords);
        if (r.finalResult) onFinal(r.recognizedWords);
      },
      onSoundLevelChange: onLevel == null ? null : (double l) => onLevel(l),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
        localeId: preferEnglish ? _englishLocaleId : null,
        pauseFor: pauseFor,
        listenFor: listenFor,
      ),
    );
  }

  /// Stops listening and asks for a final result (the normal "I'm done" path).
  Future<void> stop() async {
    try {
      await _speech.stop();
    } on Object catch (e, st) {
      AppLogger.warning('Speech stop failed', e, st);
    }
  }

  /// Abandons the session with no final result (used when the user backs out).
  Future<void> cancel() async {
    try {
      await _speech.cancel();
    } on Object catch (e, st) {
      AppLogger.warning('Speech cancel failed', e, st);
    }
  }
}

final speechServiceProvider = Provider<SpeechService>((ref) => SpeechService());
