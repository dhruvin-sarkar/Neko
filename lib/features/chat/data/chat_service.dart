import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart' show XFile;

import '../../../core/utils/logger.dart';
import '../models/chat_attachment.dart';
import '../models/chat_message.dart';

/// Contract for the AI backend: send the [history] and stream the reply token
/// by token.
abstract class ChatService {
  Stream<String> streamReply(List<ChatMessage> history);
}

/// Raised when the AI request fails; shown to the user as a friendly note.
class ChatException implements Exception {
  const ChatException([
    this.message = 'The assistant is unavailable right now.',
  ]);
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

  /// Placeholder shipped in `.env.example`; treated as "no key set".
  static const String _placeholderKey = 'replace_with_your_hackclub_api_key';

  String get _apiKey {
    final String key = dotenv.get('HACKCLUB_API_KEY', fallback: '');
    if (key.isNotEmpty) return key;
    return dotenv.get('AI_API_KEY', fallback: '');
  }

  String get _baseUrl =>
      dotenv.get('AI_BASE_URL', fallback: 'https://ai.hackclub.com/proxy/v1');
  String get _model =>
      dotenv.get('AI_MODEL', fallback: 'google/gemini-3-flash-preview');

  @override
  Stream<String> streamReply(List<ChatMessage> history) async* {
    final String apiKey = _apiKey;
    if (apiKey.isEmpty || apiKey == _placeholderKey) {
      throw const ChatException(
        'Add your Hack Club AI key to the .env file '
        '(HACKCLUB_API_KEY) to chat with Neko.',
      );
    }

    final List<Map<String, dynamic>> messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
    ];
    for (final ChatMessage m in history) {
      // Skip the empty assistant placeholder appended while we wait for a reply.
      if (m.role == ChatRole.assistant && m.content.trim().isEmpty) continue;
      messages.add(await _encodeMessage(m));
    }

    final http.Request request =
        http.Request('POST', Uri.parse('$_baseUrl/chat/completions'))
          ..headers.addAll(<String, String>{
            'Authorization': 'Bearer $apiKey',
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

  /// Builds the API message for [m]. A user message carrying image attachments
  /// becomes a multi-part content array (text + inline images) so vision models
  /// can actually see them; everything else stays a plain text message.
  Future<Map<String, dynamic>> _encodeMessage(ChatMessage m) async {
    final String role = m.isUser ? 'user' : 'assistant';
    final List<ChatAttachment> images = m.isUser
        ? m.attachments.where((ChatAttachment a) => a.isImage).toList()
        : const <ChatAttachment>[];

    if (images.isEmpty) {
      return <String, dynamic>{'role': role, 'content': m.content};
    }

    final List<Map<String, dynamic>> parts = <Map<String, dynamic>>[
      if (m.content.trim().isNotEmpty)
        <String, dynamic>{'type': 'text', 'text': m.content},
    ];
    for (final ChatAttachment a in images) {
      final String? dataUrl = await _toDataUrl(a.path);
      if (dataUrl != null) {
        parts.add(<String, dynamic>{
          'type': 'image_url',
          'image_url': <String, String>{'url': dataUrl},
        });
      }
    }
    // If every image failed to load, fall back to plain text so we still send
    // something coherent.
    if (parts.isEmpty) {
      return <String, dynamic>{'role': role, 'content': m.content};
    }
    return <String, dynamic>{'role': role, 'content': parts};
  }

  /// Reads a local image and encodes it as a base64 data URL the API accepts.
  /// Returns null if the file can't be read, so a bad attachment never blocks
  /// the message.
  Future<String?> _toDataUrl(String path) async {
    try {
      final List<int> bytes = await XFile(path).readAsBytes();
      return 'data:${_mimeFor(path)};base64,${base64Encode(bytes)}';
    } on Object catch (e, st) {
      AppLogger.warning('Could not attach image to chat', e, st);
      return null;
    }
  }

  String _mimeFor(String path) {
    final String p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.gif')) return 'image/gif';
    if (p.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}

/// App-wide [ChatService].
final chatServiceProvider = Provider<ChatService>((ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return HackClubChatService(client);
});
