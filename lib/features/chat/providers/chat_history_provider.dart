import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/logger.dart';
import '../../onboarding/data/onboarding_persistence.dart';
import '../models/chat_conversation.dart';

/// Transcripts are stored per Firebase account: the key carries the owner's
/// uid, so a second account signing in on the same device can never read the
/// first one's conversations.
String _historyKeyFor(String uid) => 'chat_history_v1_$uid';

/// The un-namespaced key older builds wrote. Purged on sight — an orphaned
/// global transcript can't be attributed to an account, so it must not stay.
const String _legacyHistoryKey = 'chat_history_v1';

/// Deletes the stored transcripts for [uid] (and any legacy global entry).
/// Called on sign-out so conversations never outlive the account session on a
/// shared device.
Future<void> clearChatHistoryFor(SharedPreferences prefs, String? uid) async {
  if (uid != null && uid.isNotEmpty) {
    await prefs.remove(_historyKeyFor(uid));
  }
  await prefs.remove(_legacyHistoryKey);
}

/// Persists past conversations on-device and exposes them newest-first.
final chatHistoryProvider =
    NotifierProvider<ChatHistoryController, List<ChatConversation>>(
      ChatHistoryController.new,
    );

class ChatHistoryController extends Notifier<List<ChatConversation>> {
  String? _uid;

  @override
  List<ChatConversation> build() {
    // Watching the auth state re-runs this build on every account switch, so
    // the visible history always belongs to the signed-in user.
    final String? previousUid = _uid;
    _uid = ref.watch(
      authStateChangesProvider.select((value) => value.valueOrNull?.uid),
    );
    final SharedPreferences prefs = ref.watch(sharedPreferencesProvider);

    // Belt-and-braces on sign-out: if a reply completed in the tick between
    // AuthController's key wipe and this rebuild, it re-created the previous
    // account's key. Re-remove it here so a signed-out transcript can't linger.
    if (previousUid != null && _uid == null) {
      unawaited(prefs.remove(_historyKeyFor(previousUid)));
    }

    // One-time hygiene: drop the shared key older builds used.
    if (prefs.containsKey(_legacyHistoryKey)) {
      unawaited(prefs.remove(_legacyHistoryKey));
    }

    final String? uid = _uid;
    if (uid == null) return const [];

    final String? raw = prefs.getString(_historyKeyFor(uid));
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

  /// Writes the current history for the signed-in user. Returns `true` when the
  /// write reached disk (or there was nothing to do), and `false` when it was
  /// rejected — disk full, a platform-channel error, corrupted prefs. State is
  /// updated optimistically before this runs, so a `false` is the caller's only
  /// signal that the in-memory change did NOT persist and will be lost on the
  /// next reload; the mutators forward it rather than swallowing it silently.
  Future<bool> _persist() async {
    final String? uid = _uid;
    // Signed out — there's no account to attribute the write to.
    if (uid == null) return true;
    final String raw = jsonEncode([for (final c in state) c.toJson()]);
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setString(_historyKeyFor(uid), raw);
      return true;
    } on Object catch (e, st) {
      AppLogger.error('Failed to persist chat history', e, st);
      return false;
    }
  }

  /// Inserts or updates [conversation] (matched by id), keeping newest first.
  /// Returns whether the change reached disk (see [_persist]).
  Future<bool> upsert(ChatConversation conversation) async {
    final List<ChatConversation> next = [
      conversation,
      for (final ChatConversation c in state)
        if (c.id != conversation.id) c,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    state = next;
    return _persist();
  }

  /// Removes the conversation with [id]. Returns whether the change reached disk.
  Future<bool> remove(String id) async {
    state = [
      for (final ChatConversation c in state)
        if (c.id != id) c,
    ];
    return _persist();
  }

  /// Clears all history for the signed-in user. Returns whether it reached disk.
  Future<bool> clearAll() async {
    state = const [];
    return _persist();
  }
}
