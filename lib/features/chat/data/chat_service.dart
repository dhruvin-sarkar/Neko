import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';

/// Contract for the AI backend.
///
/// The conversation [history] is sent and the reply is streamed back token by
/// token (so the UI can show it appearing live and offer a Stop control).
/// Swap [_StubChatService] for the real LLM client when the external API is
/// available — nothing else in the chat feature needs to change.
abstract class ChatService {
  Stream<String> streamReply(List<ChatMessage> history);
}

/// Placeholder until the external LLM API is provided. Streams a fixed reply so
/// the full send / stream / stop flow is exercised end-to-end.
class _StubChatService implements ChatService {
  @override
  Stream<String> streamReply(List<ChatMessage> history) async* {
    const String reply =
        "Hi! I'm Neko's assistant. I'm not connected to a language model yet — "
        "once the API is set up I'll help you with your cats' care, reminders, "
        "and questions right here.";
    await Future<void>.delayed(const Duration(milliseconds: 350));
    for (final String word in reply.split(' ')) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      yield '$word ';
    }
  }
}

/// App-wide [ChatService]. Replace the stub with the real client here.
final chatServiceProvider = Provider<ChatService>((ref) => _StubChatService());
