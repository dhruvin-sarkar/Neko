import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chat_service.dart';
import '../models/chat_attachment.dart';
import '../models/chat_message.dart';

/// Immutable snapshot of the conversation.
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

/// Owns the conversation: appends the user's message, streams the assistant's
/// reply in, and supports stopping mid-generation.
final chatControllerProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatController extends Notifier<ChatState> {
  StreamSubscription<String>? _sub;
  int _seq = 0;

  @override
  ChatState build() {
    ref.onDispose(() => _sub?.cancel());
    return const ChatState();
  }

  String _nextId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

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

    final StringBuffer buffer = StringBuffer();
    _sub = ref
        .read(chatServiceProvider)
        .streamReply(state.messages)
        .listen(
          (token) {
            buffer.write(token);
            _setAssistant(assistantId, buffer.toString(), streaming: true);
          },
          onDone: () {
            _setAssistant(
              assistantId,
              buffer.toString().trimRight(),
              streaming: false,
            );
            state = state.copyWith(isGenerating: false);
            _sub = null;
          },
          onError: (_) {
            _setAssistant(
              assistantId,
              'Sorry — something went wrong. Please try again.',
              streaming: false,
            );
            state = state.copyWith(isGenerating: false);
            _sub = null;
          },
        );
  }

  void _setAssistant(String id, String content, {required bool streaming}) {
    state = state.copyWith(
      messages: [
        for (final ChatMessage m in state.messages)
          if (m.id == id)
            m.copyWith(content: content, isStreaming: streaming)
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
  }

  /// Clears the conversation.
  void clear() {
    _sub?.cancel();
    _sub = null;
    state = const ChatState();
  }
}
