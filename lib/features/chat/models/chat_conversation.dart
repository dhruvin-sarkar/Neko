import 'package:flutter/foundation.dart';

import 'chat_message.dart';

/// A saved conversation in the chat history. Attachments are intentionally not
/// persisted (they reference ephemeral local files); only the text transcript
/// is stored.
@immutable
class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'messages': [
      for (final ChatMessage m in messages)
        <String, dynamic>{
          'id': m.id,
          'role': m.role.name,
          'content': m.content,
        },
    ],
  };

  static ChatConversation fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = (json['messages'] as List<dynamic>?) ?? const [];
    return ChatConversation(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? 'Conversation',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        (json['updatedAt'] as num?)?.toInt() ?? 0,
      ),
      messages: [
        for (final dynamic e in raw)
          ChatMessage(
            id: (e as Map<String, dynamic>)['id'] as String,
            role: ChatRole.values.firstWhere(
              (r) => r.name == e['role'],
              orElse: () => ChatRole.assistant,
            ),
            content: (e['content'] as String?) ?? '',
          ),
      ],
    );
  }

  /// A short preview line for the history list.
  String get preview {
    for (final ChatMessage m in messages) {
      if (m.isUser && m.content.trim().isNotEmpty) return m.content.trim();
    }
    return messages.isNotEmpty ? messages.first.content.trim() : title;
  }
}
