import 'package:flutter/foundation.dart';

import '../../../shared/services/search_service.dart';
import 'chat_attachment.dart';

/// Who authored a chat message.
enum ChatRole { user, assistant }

/// A single message in the AI conversation. Immutable; updates produce a new
/// instance via [copyWith] (used while the assistant's reply streams in).
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.attachments = const <ChatAttachment>[],
    this.isStreaming = false,
    this.isError = false,
    this.results = const <SearchResult>[],
  });

  final String id;
  final ChatRole role;
  final String content;
  final List<ChatAttachment> attachments;

  /// True while the assistant's reply is still being received.
  final bool isStreaming;

  /// True when this assistant message is a failure notice (network / API error)
  /// rather than a real reply — the bubble shows the 404 cat for it.
  final bool isError;

  /// Web results for a "results" query (the bubble renders a tappable list).
  /// Transient — not persisted, so a reloaded conversation shows the summary
  /// text only.
  final List<SearchResult> results;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    bool? isError,
    List<SearchResult>? results,
  }) => ChatMessage(
    id: id,
    role: role,
    content: content ?? this.content,
    attachments: attachments,
    isStreaming: isStreaming ?? this.isStreaming,
    isError: isError ?? this.isError,
    results: results ?? this.results,
  );
}
