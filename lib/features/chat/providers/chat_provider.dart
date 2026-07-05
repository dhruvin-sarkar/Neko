import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // A "best/top/which…" question with no photo tries a real web search first
    // and shows a tappable list; it falls back to a conversational answer if the
    // search is empty or unavailable — the same routing the voice flow uses.
    if (attachments.isEmpty && isSearchQuery(trimmed)) {
      final List<SearchResult> results = await ref
          .read(searchServiceProvider)
          .search(trimmed);
      // Bail if the turn was stopped / a new chat started during the search.
      if (!state.isGenerating) return;
      if (results.isNotEmpty) {
        _setAssistantResults(assistantId, results);
        state = state.copyWith(isGenerating: false);
        _saveCurrent();
        return;
      }
      // else fall through to a normal streamed reply
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
            state = state.copyWith(isGenerating: false);
            _sub = null;
            _saveCurrent();
          },
          onError: (Object error) {
            final String message = error is ChatException
                ? error.message
                : 'Sorry — something went wrong. Please try again.';
            _setAssistant(assistantId, message, streaming: false, isError: true);
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
            m.copyWith(content: content, isStreaming: streaming, isError: isError)
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
    if (state.messages.isEmpty) return;
    final String title = state.messages
        .firstWhere(
          (m) => m.isUser && m.content.trim().isNotEmpty,
          orElse: () => state.messages.first,
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
            messages: state.messages,
          ),
        );
  }
}
