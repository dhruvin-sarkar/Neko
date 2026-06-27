import 'package:flutter/foundation.dart';

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
  });

  final String id;
  final ChatRole role;
  final String content;
  final List<ChatAttachment> attachments;

  /// True while the assistant's reply is still being received.
  final bool isStreaming;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({String? content, bool? isStreaming}) => ChatMessage(
    id: id,
    role: role,
    content: content ?? this.content,
    attachments: attachments,
    isStreaming: isStreaming ?? this.isStreaming,
  );
}
