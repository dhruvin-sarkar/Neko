import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../../onboarding/data/onboarding_persistence.dart';
import '../models/chat_conversation.dart';

const String _kHistoryKey = 'chat_history_v1';

/// Persists past conversations on-device and exposes them newest-first.
final chatHistoryProvider =
    NotifierProvider<ChatHistoryController, List<ChatConversation>>(
      ChatHistoryController.new,
    );

class ChatHistoryController extends Notifier<List<ChatConversation>> {
  @override
  List<ChatConversation> build() {
    final String? raw = ref
        .watch(sharedPreferencesProvider)
        .getString(_kHistoryKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final List<ChatConversation> parsed = [
        for (final dynamic e in list)
          ChatConversation.fromJson(e as Map<String, dynamic>),
      ];
      parsed.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return parsed;
    } on Object catch (e, st) {
      AppLogger.error('Failed to load chat history; starting empty', e, st);
      return const [];
    }
  }

  Future<void> _persist() async {
    final String raw = jsonEncode([for (final c in state) c.toJson()]);
    await ref.read(sharedPreferencesProvider).setString(_kHistoryKey, raw);
  }

  /// Inserts or updates [conversation] (matched by id), keeping newest first.
  Future<void> upsert(ChatConversation conversation) async {
    final List<ChatConversation> next = [
      conversation,
      for (final ChatConversation c in state)
        if (c.id != conversation.id) c,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = next;
    await _persist();
  }

  Future<void> remove(String id) async {
    state = [
      for (final ChatConversation c in state)
        if (c.id != id) c,
    ];
    await _persist();
  }

  Future<void> clearAll() async {
    state = const [];
    await _persist();
  }
}
