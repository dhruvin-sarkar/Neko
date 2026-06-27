import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/utils/logger.dart';
import '../models/chat_message.dart';

/// Contract for the AI backend: send the [history] and stream the reply token
/// by token.
abstract class ChatService {
  Stream<String> streamReply(List<ChatMessage> history);
}

/// Raised when the AI request fails; shown to the user as a friendly note.
class ChatException implements Exception {
  const ChatException([this.message = 'The assistant is unavailable right now.']);
  final String message;
}

const String _systemPrompt =
    'You are Neko, the assistant inside a cat-care companion app. Your only '
    'purpose is helping cat owners with cat care, health, nutrition, '
    'behaviour, grooming, and reminders. Stay strictly on this topic. If a '
    'request is outside cat care, politely decline in one sentence and steer '
    'the conversation back to caring for their cat. '
    'Write in a warm, professional, and concise tone. Use plain prose in '
    'clear, complete sentences. Do not use asterisks, markdown formatting, '
    'bullet characters, or emojis in your replies. When you need to list '
    'steps, write them as a short numbered list using plain text (for example '
    '"1." on its own line). For anything that needs a veterinarian, recommend '
    'consulting one rather than giving a diagnosis.';

/// OpenAI-compatible chat service (Hack Club proxy). Streams Server-Sent
/// Events when available, otherwise falls back to a single JSON completion.
class HackClubChatService implements ChatService {
  HackClubChatService(this._client);

  final http.Client _client;

  String get _apiKey => dotenv.get('AI_API_KEY', fallback: '');
  String get _baseUrl => dotenv.get(
    'AI_BASE_URL',
    fallback: 'https://ai.hackclub.com/proxy/v1',
  );
  String get _model =>
      dotenv.get('AI_MODEL', fallback: 'google/gemini-3-flash-preview');

  @override
  Stream<String> streamReply(List<ChatMessage> history) async* {
    final List<Map<String, String>> messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      for (final ChatMessage m in history)
        if (!(m.role == ChatRole.assistant && m.content.trim().isEmpty))
          {'role': m.isUser ? 'user' : 'assistant', 'content': m.content},
    ];

    final http.Request request =
        http.Request('POST', Uri.parse('$_baseUrl/chat/completions'))
          ..headers.addAll(<String, String>{
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream',
          })
          ..body = jsonEncode(<String, dynamic>{
            'model': _model,
            'messages': messages,
            'stream': true,
            'temperature': 0.7,
          });

    late final http.StreamedResponse response;
    try {
      response = await _client.send(request);
    } on Object catch (e, st) {
      AppLogger.warning('AI request failed', e, st);
      throw const ChatException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final String body = await response.stream.bytesToString();
      AppLogger.warning('AI HTTP ${response.statusCode}: $body');
      throw const ChatException();
    }

    final String contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text/event-stream')) {
      yield* _parseSse(response.stream);
    } else {
      // Non-streaming fallback.
      final String body = await response.stream.bytesToString();
      yield _extractContent(body);
    }
  }

  Stream<String> _parseSse(Stream<List<int>> byteStream) async* {
    final Stream<String> lines = byteStream
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final String line in lines) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
      final String data = trimmed.substring(5).trim();
      if (data == '[DONE]') break;
      try {
        final Map<String, dynamic> json =
            jsonDecode(data) as Map<String, dynamic>;
        final List<dynamic>? choices = json['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) continue;
        final Map<String, dynamic>? delta =
            (choices.first as Map<String, dynamic>)['delta']
                as Map<String, dynamic>?;
        final String? content = delta?['content'] as String?;
        if (content != null && content.isNotEmpty) yield content;
      } on Object {
        // Ignore malformed chunks.
      }
    }
  }

  String _extractContent(String body) {
    try {
      final Map<String, dynamic> json =
          jsonDecode(body) as Map<String, dynamic>;
      final List<dynamic> choices = json['choices'] as List<dynamic>;
      final Map<String, dynamic> message =
          (choices.first as Map<String, dynamic>)['message']
              as Map<String, dynamic>;
      return (message['content'] as String?) ?? '';
    } on Object catch (e, st) {
      AppLogger.warning('AI response parse failed', e, st);
      throw const ChatException();
    }
  }
}

/// App-wide [ChatService].
final chatServiceProvider = Provider<ChatService>((ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return HackClubChatService(client);
});
