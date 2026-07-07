import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../shared/services/search_service.dart';
import '../../onboarding/models/cat_profile.dart';
import '../../profiles/providers/profile_provider.dart';
import '../data/chat_service.dart';
import '../models/chat_attachment.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'chat_history_provider.dart';

/// Immutable snapshot of the active conversation.
@immutable
class ChatState {
  const ChatState({
    this.messages = const <ChatMessage>[],
    this.isGenerating = false,
  });

  final List<ChatMessage> messages;
  final bool isGenerating;

  bool get isEmpty => messages.isEmpty;

  ChatState copyWith({List<ChatMessage>? messages, bool? isGenerating}) =>
      ChatState(
        messages: messages ?? this.messages,
        isGenerating: isGenerating ?? this.isGenerating,
      );
}

/// Owns the active conversation: appends the user's message, streams the
/// assistant's reply, supports stopping mid-generation, and saves finished
/// conversations into the persisted history.
final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  StreamSubscription<String>? _sub;
  int _seq = 0;
  late String _conversationId;

  @override
  ChatState build() {
    // The active transcript belongs to one account. Watching the uid re-runs
    // this build on every sign-in/out, so the previous user's messages are
    // dropped before they can render — or be saved — under the next account
    // (the history provider already rebuilds per uid; without this, the live
    // conversation survived in memory across a sign-out and leaked).
    ref.watch(authStateChangesProvider.select((v) => v.valueOrNull?.uid));
    _sub?.cancel();
    _sub = null;
    _conversationId = _nextId();
    ref.onDispose(() => _sub?.cancel());
    return const ChatState();
  }

  String _nextId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  /// Sends [text] (+ any [attachments]) and streams the assistant's reply.
  Future<void> send(String text, List<ChatAttachment> attachments) async {
    if (state.isGenerating) return;
    final String trimmed = text.trim();
    if (trimmed.isEmpty && attachments.isEmpty) return;

    final ChatMessage user = ChatMessage(
      id: _nextId(),
      role: ChatRole.user,
      content: trimmed,
      attachments: List<ChatAttachment>.unmodifiable(attachments),
    );
    final String assistantId = _nextId();
    final ChatMessage assistant = ChatMessage(
      id: assistantId,
      role: ChatRole.assistant,
      content: '',
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, user, assistant],
      isGenerating: true,
    );

    // A "best/top/which…" question with no photo is a "results" query. If a
    // search API key is configured we try a real web search for a tappable
    // in-app list; either way we always attach a one-tap Google search (opens in
    // the browser) so there's a real path to live results even with no key.
    final bool wantsWeb = attachments.isEmpty && isSearchQuery(trimmed);
    final SearchService searchSvc = ref.read(searchServiceProvider);
    final SearchResult? webResult = wantsWeb
        ? SearchResult(
            title: 'Search the web for “$trimmed”',
            description: 'Tap to dig through the full web results',
            url: searchSvc.webSearchUrl(trimmed),
          )
        : null;

    if (wantsWeb && searchSvc.hasKey) {
      final List<SearchResult> results = await searchSvc.search(trimmed);
      // Bail unless THIS turn is still the live one: the ~8s search can outlive
      // a Stop or a New chat, and a bare isGenerating check would let the stale
      // result hijack a newer turn. The placeholder (unique assistantId) must
      // still exist and still be streaming.
      final bool stillThisTurn =
          state.isGenerating &&
          state.messages.any(
            (ChatMessage m) => m.id == assistantId && m.isStreaming,
          );
      if (!stillThisTurn) return;
      if (results.isNotEmpty) {
        _setAssistantResults(assistantId, results);
        state = state.copyWith(isGenerating: false);
        _saveCurrent();
        return;
      }
      // else fall through to a normal reply + the browser-search card below
    }

    // Give the model this owner's cat profile(s) so replies are personalised.
    final List<CatProfile> cats =
        ref.read(catProfilesProvider).valueOrNull ?? const <CatProfile>[];
    final String? catContext = cats.isEmpty
        ? null
        : cats.map((CatProfile c) => c.toAIContext()).join('\n\n');

    final StringBuffer buffer = StringBuffer();
    _sub = ref
        .read(chatServiceProvider)
        .streamReply(state.messages, catContext: catContext)
        .listen(
          (token) {
            buffer.write(token);
            _setAssistant(assistantId, buffer.toString(), streaming: true);
          },
          onDone: () {
            final String text = buffer.toString().trim();
            _setAssistant(
              assistantId,
              text.isEmpty ? '…' : text,
              streaming: false,
            );
            if (webResult != null) _attachWebResult(assistantId, webResult);
            state = state.copyWith(isGenerating: false);
            _sub = null;
            _saveCurrent();
          },
          onError: (Object error) {
            final String message = error is ChatException
                ? error.message
                : 'Mrow — something tripped me up mid-pounce. Try that again?';
            _setAssistant(
              assistantId,
              message,
              streaming: false,
              isError: true,
            );
            // Even on failure, a results-style query still gets its one-tap web
            // search — a useful recovery instead of a dead end.
            if (webResult != null) _attachWebResult(assistantId, webResult);
            state = state.copyWith(isGenerating: false);
            _sub = null;
            // Persist the partial turn too, so a mid-stream network error
            // doesn't silently drop the exchange from history.
            _saveCurrent();
          },
        );
  }

  /// Records a completed Hey Neko voice exchange into the active conversation,
  /// so a spoken question and its answer show up in the transcript and are saved
  /// to history exactly like a typed turn. Skipped while a text reply is
  /// streaming, so voice never interleaves with an in-flight message.
  void appendVoiceTurn(String prompt, String reply) {
    if (state.isGenerating) return;
    final String question = prompt.trim();
    final String answer = reply.trim();
    if (question.isEmpty && answer.isEmpty) return;
    final ChatMessage user = ChatMessage(
      id: _nextId(),
      role: ChatRole.user,
      content: question,
    );
    final ChatMessage assistant = ChatMessage(
      id: _nextId(),
      role: ChatRole.assistant,
      content: answer,
    );
    state = state.copyWith(messages: [...state.messages, user, assistant]);
    _saveCurrent();
  }

  /// Fills the assistant placeholder with web results: a short summary line
  /// (which is what persists to history) plus the tappable list.
  void _setAssistantResults(String id, List<SearchResult> results) {
    final String summary =
        'Here are a few options I found:\n'
        '${results.map((SearchResult r) => '• ${r.title}').join('\n')}';
    state = state.copyWith(
      messages: [
        for (final ChatMessage m in state.messages)
          if (m.id == id)
            m.copyWith(content: summary, isStreaming: false, results: results)
          else
            m,
      ],
    );
  }

  /// Appends a one-tap "search the web" card under an assistant reply for a
  /// results-style query, so live web results are one tap away even with no
  /// search API key configured.
  void _attachWebResult(String id, SearchResult result) {
    state = state.copyWith(
      messages: [
        for (final ChatMessage m in state.messages)
          if (m.id == id) m.copyWith(results: <SearchResult>[result]) else m,
      ],
    );
  }

  void _setAssistant(
    String id,
    String content, {
    required bool streaming,
    bool isError = false,
  }) {
    state = state.copyWith(
      messages: [
        for (final ChatMessage m in state.messages)
          if (m.id == id)
            m.copyWith(
              content: content,
              isStreaming: streaming,
              isError: isError,
            )
          else
            m,
      ],
    );
  }

  /// Stops an in-progress reply, keeping whatever has streamed so far.
  void stop() {
    _sub?.cancel();
    _sub = null;
    state = state.copyWith(
      isGenerating: false,
      messages: [
        for (final ChatMessage m in state.messages)
          m.isStreaming ? m.copyWith(isStreaming: false) : m,
      ],
    );
    _saveCurrent();
  }

  /// Archives the current conversation (if any) and starts a fresh one.
  void newChat() {
    _sub?.cancel();
    _sub = null;
    _saveCurrent();
    _conversationId = _nextId();
    state = const ChatState();
  }

  /// Loads a saved [conversation] as the active one.
  void load(ChatConversation conversation) {
    _sub?.cancel();
    _sub = null;
    _saveCurrent();
    _conversationId = conversation.id;
    state = ChatState(messages: List<ChatMessage>.of(conversation.messages));
  }

  void _saveCurrent() {
    // Normalize before archiving — one choke point for every save path
    // (onDone, onError, stop, voice/safety turn, newChat, load): an archived
    // conversation must never carry a still-"typing" bubble (newChat/load can
    // fire mid-stream) or an empty assistant placeholder (Stop before the first
    // token). Un-stream survivors; drop empty assistant messages.
    final List<ChatMessage> archived = <ChatMessage>[
      for (final ChatMessage m in state.messages)
        if (!(m.role == ChatRole.assistant && m.content.trim().isEmpty))
          m.isStreaming ? m.copyWith(isStreaming: false) : m,
    ];
    if (archived.isEmpty) return;
    final String title = archived
        .firstWhere(
          (m) => m.isUser && m.content.trim().isNotEmpty,
          orElse: () => archived.first,
        )
        .content
        .trim();
    ref
        .read(chatHistoryProvider.notifier)
        .upsert(
          ChatConversation(
            id: _conversationId,
            title: title.isEmpty ? 'Conversation' : title,
            updatedAt: DateTime.now(),
            messages: archived,
          ),
        );
  }
}
