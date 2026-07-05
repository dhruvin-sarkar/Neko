import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/notch/controller/notch_controller.dart';
import '../../../core/notch/model/notch_activity.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/services/image_picker_service.dart';
import '../../chat/data/chat_service.dart';
import '../../chat/models/chat_attachment.dart';
import '../../chat/models/chat_message.dart';
import '../../chat/providers/chat_provider.dart';
import '../../onboarding/models/cat_profile.dart';
import '../../profiles/providers/profile_provider.dart';
import '../../../shared/services/search_service.dart';
import '../data/speech_service.dart';
import '../data/tts_service.dart';

/// What a spoken request wants — decided once, in [_route], on the final
/// transcript, in priority order. Camera is checked first ("look at this, is it
/// safe" must never be mis-read); then results (a "best/top/which" query wanting
/// a small set of options); everything else is a plain answer.
enum _VoiceIntent { camera, results, plain }

/// Where a Hey Neko voice session is in its lifecycle. [searching] is the web
/// lookup for a results query (its own state so the page can show the
/// cat-in-a-box search animation), [results] shows the returned list.
enum HeyNekoPhase {
  idle,
  listening,
  thinking,
  searching,
  speaking,
  results,
  error,
}

/// Immutable snapshot of the current voice session, watched by the Hey Neko
/// sheet and mirrored onto the notch island.
@immutable
class HeyNekoState {
  const HeyNekoState({
    this.phase = HeyNekoPhase.idle,
    this.transcript = '',
    this.reply = '',
    this.level = 0,
    this.message,
    this.micDenied = false,
    this.results = const <SearchResult>[],
  });

  final HeyNekoPhase phase;

  /// What Neko has heard so far (partial while listening, settled after).
  final String transcript;

  /// Neko's spoken answer (populated once it starts speaking).
  final String reply;

  /// Mic loudness (0..~10) for the live waveform.
  final double level;

  /// A hint or error message for the sheet (empty transcript, mic denied, …).
  final String? message;

  /// True when the failure was specifically the microphone being unavailable —
  /// the sheet points the user at typing instead.
  final bool micDenied;

  /// Web results for a "results" query (empty otherwise).
  final List<SearchResult> results;

  bool get isBusy =>
      phase == HeyNekoPhase.listening ||
      phase == HeyNekoPhase.thinking ||
      phase == HeyNekoPhase.searching ||
      phase == HeyNekoPhase.speaking;

  HeyNekoState copyWith({
    HeyNekoPhase? phase,
    String? transcript,
    String? reply,
    double? level,
    String? message,
    bool clearMessage = false,
    bool? micDenied,
    List<SearchResult>? results,
  }) {
    return HeyNekoState(
      phase: phase ?? this.phase,
      transcript: transcript ?? this.transcript,
      reply: reply ?? this.reply,
      level: level ?? this.level,
      message: clearMessage ? null : (message ?? this.message),
      micDenied: micDenied ?? this.micDenied,
      results: results ?? this.results,
    );
  }
}

final heyNekoControllerProvider =
    NotifierProvider<HeyNekoController, HeyNekoState>(HeyNekoController.new);

/// Drives a whole tap-to-talk turn in the main app engine: microphone → the
/// existing [ChatService] → text-to-speech, pushing each step onto the notch
/// island as an `assistant` activity. There is exactly one AI request path
/// (the shared chat service) and one waveform (the shared cat muzzle); this
/// only adds the voice plumbing around them.
class HeyNekoController extends Notifier<HeyNekoState> {
  static const String _activityId = 'hey_neko';

  StreamSubscription<String>? _replySub;
  String _heard = '';
  String _prompt = '';
  bool _finalHandled = false;
  bool _disposed = false;

  SpeechService get _speech => ref.read(speechServiceProvider);
  TtsService get _tts => ref.read(ttsServiceProvider);

  @override
  HeyNekoState build() {
    ref.onDispose(() {
      _disposed = true;
      _replySub?.cancel();
      unawaited(_speech.cancel());
      unawaited(_tts.stop());
    });
    return const HeyNekoState();
  }

  /// Starts a tap-to-talk session: mic → transcript → answer → spoken reply.
  Future<void> start() async {
    if (state.isBusy) return;
    _heard = '';
    _prompt = '';
    _finalHandled = false;
    state = const HeyNekoState(phase: HeyNekoPhase.listening);

    final bool ready = await _speech.ensureReady(
      onStatus: _onStatus,
      onError: _onSpeechError,
    );
    // Bail if the session was cancelled (sheet closed) while we awaited the mic
    // permission / init — cancel() resets the phase to idle. Without this the
    // recogniser would start and the notch activity would be pushed with no
    // sheet on screen.
    if (_disposed || state.phase != HeyNekoPhase.listening) return;
    if (!ready) {
      state = state.copyWith(
        phase: HeyNekoPhase.error,
        micDenied: true,
        message: 'Neko can’t hear you — microphone access is off. '
            'You can type your question instead.',
      );
      return;
    }

    await _pushActivity(title: 'Listening…', subtitle: 'Say something to Neko');

    try {
      // No onLevel: the dark AI-notch page has no mic-reactive visual, and
      // streaming the level would rebuild the whole page ~20x/sec for nothing.
      await _speech.listen(onWords: _onWords, onFinal: _onFinal);
    } on Object catch (e, st) {
      AppLogger.warning('Hey Neko failed to start listening', e, st);
      if (_disposed) return;
      unawaited(_removeActivity());
      state = state.copyWith(
        phase: HeyNekoPhase.error,
        message: 'Something went wrong with the mic. Please try again.',
      );
    }
  }

  /// Stops listening early and lets Neko answer with whatever was heard.
  Future<void> submit() async {
    if (state.phase != HeyNekoPhase.listening) return;
    await _speech.stop();
    // The final-result / status handler carries on from here.
  }

  /// Ends the session entirely (the user closed the sheet or tapped stop).
  Future<void> cancel() async {
    // Suppress any speech result still in flight so a late final can't revive
    // the session after it's been abandoned.
    _finalHandled = true;
    _replySub?.cancel();
    _replySub = null;
    await _speech.cancel();
    await _tts.stop();
    await _removeActivity();
    if (_disposed) return;
    state = const HeyNekoState();
  }

  // ── Speech callbacks ────────────────────────────────────────────────────────

  void _onWords(String words) {
    if (_disposed || state.phase != HeyNekoPhase.listening) return;
    _heard = words;
    state = state.copyWith(transcript: words);
    if (words.trim().isNotEmpty) {
      unawaited(_updateActivity(title: 'Listening…', subtitle: words));
    }
  }

  void _onStatus(String status) {
    // If the platform ends the session without a final result (e.g. silence),
    // treat whatever we have as final so the flow never hangs.
    if (_disposed) return;
    if ((status == 'done' || status == 'notListening') &&
        state.phase == HeyNekoPhase.listening &&
        !_finalHandled) {
      _onFinal(_heard);
    }
  }

  void _onSpeechError(String error) {
    // A no-match / timeout error just means Neko heard nothing — fall through to
    // the empty-transcript path rather than surfacing a raw error string.
    if (_disposed || state.phase != HeyNekoPhase.listening) return;
    if (!_finalHandled) _onFinal(_heard);
  }

  void _onFinal(String words) {
    // Only act while still listening. A final result delivered after the
    // session was cancelled (classically: tap "Done" — which calls stop() and
    // requests a final — then immediately close the sheet) must not resurrect
    // the pipeline into thinking/speaking with no sheet on screen.
    if (_disposed || _finalHandled || state.phase != HeyNekoPhase.listening) {
      return;
    }
    _finalHandled = true;
    final String prompt = words.trim();
    if (prompt.isEmpty) {
      unawaited(_removeActivity());
      state = state.copyWith(
        phase: HeyNekoPhase.error,
        message: 'Neko didn’t catch that. Tap the mic to try again.',
      );
      return;
    }
    _prompt = prompt;
    // One decision, on the final transcript: camera ("look at this") → snap +
    // scan; results ("best/top/which…") → web search; else a plain answer.
    switch (_route(prompt)) {
      case _VoiceIntent.camera:
        state = state.copyWith(phase: HeyNekoPhase.thinking, transcript: prompt);
        unawaited(_updateActivity(title: 'Neko’s looking…', subtitle: prompt));
        unawaited(_scan(prompt));
      case _VoiceIntent.results:
        state = state.copyWith(
          phase: HeyNekoPhase.searching,
          transcript: prompt,
        );
        unawaited(_updateActivity(title: 'Neko’s searching…', subtitle: prompt));
        unawaited(_search(prompt));
      case _VoiceIntent.plain:
        state = state.copyWith(phase: HeyNekoPhase.thinking, transcript: prompt);
        unawaited(_updateActivity(title: 'Neko’s thinking…', subtitle: prompt));
        _think(prompt);
    }
  }

  // Camera cues all reference a physical object in view ("this" / "that"), so a
  // plain advice question ("is chocolate toxic to cats?", "is it safe to let my
  // cat outside?") is answered by voice instead of pointlessly opening the
  // camera. "is this lily safe" still routes to the camera.
  static const List<String> _cameraCues = <String>[
    'look at this',
    'look at that',
    'is this safe',
    'is that safe',
    'is this poisonous',
    'is this toxic',
    'what is this',
    "what's this",
    'check this',
    'scan this',
    'does this look',
    'can she have this',
    'can he have this',
    'can they have this',
    'have this',
    'eat this',
  ];

  _VoiceIntent _route(String transcript) {
    final String t = transcript.toLowerCase();
    for (final String cue in _cameraCues) {
      if (t.contains(cue)) return _VoiceIntent.camera;
    }
    // Results cues (best/top/which…) share one definition with the chat
    // composer, so voice and typed queries route the same way.
    if (isSearchQuery(transcript)) return _VoiceIntent.results;
    return _VoiceIntent.plain;
  }

  /// The results branch: a real web search via [SearchService]. On any
  /// empty/failed result it falls back to a plain spoken answer rather than an
  /// empty panel, so the feature degrades cleanly when search is unavailable.
  Future<void> _search(String prompt) async {
    final List<SearchResult> results = await ref
        .read(searchServiceProvider)
        .search(prompt);
    if (_disposed || state.phase != HeyNekoPhase.searching) return;
    if (results.isEmpty) {
      state = state.copyWith(phase: HeyNekoPhase.thinking);
      _think(prompt);
      return;
    }
    state = state.copyWith(phase: HeyNekoPhase.results, results: results);
    await _updateActivity(
      title: 'Neko found ${results.length}',
      subtitle: results.first.title,
    );
    ref
        .read(chatControllerProvider.notifier)
        .appendVoiceTurn(
          _prompt,
          'Here are a few options I found:\n'
          '${results.map((SearchResult r) => '• ${r.title}').join('\n')}',
        );
    unawaited(_tts.speak('Here are a few options I found.'));
  }

  /// The camera branch: snap a photo and run it through the exact same
  /// vision + cat-safety path the attach-menu scan uses (`safety: true`), then
  /// speak the verdict. No photo → fall back to a plain spoken answer.
  Future<void> _scan(String prompt) async {
    final String? path = await ref
        .read(imagePickerServiceProvider)
        .pick(ImageSource.camera);
    // The camera backgrounds the app; if the session was cancelled while it was
    // open (phase left `thinking`), don't resurrect it into a spoken answer.
    if (_disposed || state.phase != HeyNekoPhase.thinking) return;
    if (path == null) {
      _think(prompt);
      return;
    }

    final List<CatProfile> cats =
        ref.read(catProfilesProvider).valueOrNull ?? const <CatProfile>[];
    final String? catContext = cats.isEmpty
        ? null
        : cats.map((CatProfile c) => c.toAIContext()).join('\n\n');

    final ChatMessage message = ChatMessage(
      id: 'hey-neko-cam',
      role: ChatRole.user,
      content: prompt.isEmpty ? 'Is this safe for my cat?' : prompt,
      attachments: <ChatAttachment>[
        ChatAttachment(path: path, name: 'hey-neko-scan'),
      ],
    );
    final StringBuffer buffer = StringBuffer();
    _replySub?.cancel();
    _replySub = ref
        .read(chatServiceProvider)
        .streamReply(
          <ChatMessage>[message],
          catContext: catContext,
          spoken: true,
          safety: true,
        )
        .listen(
          buffer.write,
          onDone: () {
            _replySub = null;
            unawaited(_speak(buffer.toString().trim()));
          },
          onError: (Object error) {
            _replySub = null;
            if (_disposed) return;
            final String msg = error is ChatException
                ? error.message
                : 'Sorry — the safety check failed. Please try again.';
            unawaited(_removeActivity());
            state = state.copyWith(phase: HeyNekoPhase.error, message: msg);
          },
        );
  }

  // ── Thinking + speaking ─────────────────────────────────────────────────────

  void _think(String prompt) {
    final List<CatProfile> cats =
        ref.read(catProfilesProvider).valueOrNull ?? const <CatProfile>[];
    final String? catContext = cats.isEmpty
        ? null
        : cats.map((CatProfile c) => c.toAIContext()).join('\n\n');

    final ChatMessage message = ChatMessage(
      id: 'hey-neko',
      role: ChatRole.user,
      content: prompt,
    );
    final StringBuffer buffer = StringBuffer();
    _replySub?.cancel();
    _replySub = ref
        .read(chatServiceProvider)
        .streamReply(
          <ChatMessage>[message],
          catContext: catContext,
          spoken: true,
        )
        .listen(
          buffer.write,
          onDone: () {
            _replySub = null;
            unawaited(_speak(buffer.toString().trim()));
          },
          onError: (Object error) {
            _replySub = null;
            if (_disposed) return;
            final String msg = error is ChatException
                ? error.message
                : 'Sorry — something went wrong. Please try again.';
            unawaited(_removeActivity());
            state = state.copyWith(phase: HeyNekoPhase.error, message: msg);
          },
        );
  }

  Future<void> _speak(String reply) async {
    if (_disposed) return;
    if (reply.isEmpty) {
      await _removeActivity();
      if (_disposed) return;
      state = state.copyWith(
        phase: HeyNekoPhase.error,
        message: 'Neko didn’t have an answer for that. Try rephrasing.',
      );
      return;
    }
    state = state.copyWith(phase: HeyNekoPhase.speaking, reply: reply);
    await _updateActivity(title: 'Neko says', subtitle: reply);
    // Record the exchange so it shows in the chat transcript and history.
    ref.read(chatControllerProvider.notifier).appendVoiceTurn(_prompt, reply);
    await _tts.speak(reply);
    if (_disposed) return;
    await _removeActivity();
    if (_disposed) return;
    state = state.copyWith(phase: HeyNekoPhase.idle);
  }

  // ── Notch mirror ────────────────────────────────────────────────────────────

  NotchActivity _activity({required String title, required String subtitle}) {
    return NotchActivity(
      type: NotchActivityType.assistant,
      id: _activityId,
      title: title,
      subtitle: subtitle,
      isPlaying: true,
      ongoing: true,
    );
  }

  Future<void> _pushActivity({
    required String title,
    required String subtitle,
  }) {
    return ref
        .read(notchControllerProvider.notifier)
        .showActivity(_activity(title: title, subtitle: subtitle));
  }

  Future<void> _updateActivity({
    required String title,
    required String subtitle,
  }) {
    return ref
        .read(notchControllerProvider.notifier)
        .updateActivity(_activity(title: title, subtitle: subtitle));
  }

  Future<void> _removeActivity() {
    return ref
        .read(notchControllerProvider.notifier)
        .removeActivity(id: _activityId);
  }
}
