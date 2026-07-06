import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/logger.dart';

/// One web result for the "results" mode (voice or chat).
@immutable
class SearchResult {
  const SearchResult({
    required this.title,
    required this.description,
    required this.url,
  });

  final String title;
  final String description;
  final String url;
}

/// Cues that a query wants a small SET of options rather than one answer. Shared
/// by the voice router and the chat composer so both route the same way.
const List<String> _searchCues = <String>[
  'best ',
  'top ',
  'recommend',
  'which ',
  'compare',
  'cheapest',
  'find me',
  'search',
  'search for',
  'look up',
  'lookup',
  'browse',
  'research',
  'find',
  'show me',
  'look for',
  'should i buy',
  "what's a good",
  'what is a good',
  'suggest',
  'good brand',
];

/// Whether [text] reads like a "give me options" query worth a web search. A
/// mis-classification is low-harm: an empty/failed search falls back to a plain
/// answer either way.
bool isSearchQuery(String text) {
  final String t = text.toLowerCase().trim();
  if (t.isEmpty) return false;

  for (final String cue in _searchCues) {
    if (t.contains(cue)) return true;
  }

  // Avoid misclassifying ordinary questions that only happen to contain a
  // generic verb like "find" or "look". The explicit search phrases above
  // already cover the intended voice queries; this fallback keeps the detector
  // conservative for plain conversational prompts.
  return false;
}

/// Real web search via Hack Club's Brave Search pass-through
/// (`search.hackclub.com`, Bearer-authenticated like the AI proxy).
///
/// Deliberately fail-soft: any missing key, HTTP error, or parse problem returns
/// an empty list, and the caller then falls back to a plain answer rather than
/// showing a broken panel. The query and response bodies are never logged
/// outside debug builds, matching the AI service's restraint.
class SearchService {
  SearchService(this._client);

  final http.Client _client;

  static const String _placeholderKey = 'replace_with_your_hackclub_search_key';

  String get _key => dotenv.get('SEARCH_API_KEY', fallback: '');
  String get _baseUrl =>
      dotenv.get('SEARCH_BASE_URL', fallback: 'https://search.hackclub.com');

  /// Whether a usable API key is configured. When false we skip the API call
  /// entirely and go straight to the browser fallback.
  bool get hasKey {
    final String k = _key;
    return k.isNotEmpty && k != _placeholderKey;
  }

  /// A normal browser URL that runs [query] on Google. This is the always-free,
  /// no-key path: any results-style query can open real web results in one tap,
  /// even when no search API is configured (or Hack Club's is down). The app
  /// can't scrape Google's HTML — but launching the browser to it works fine.
  String webSearchUrl(String query) =>
      'https://www.google.com/search?q=${Uri.encodeQueryComponent(query.trim())}';

  /// Brave's native API authenticates with an `X-Subscription-Token` header;
  /// Hack Club's pass-through uses `Authorization: Bearer` (like the AI proxy).
  /// Auto-select by host so the same code works with either — point
  /// `SEARCH_BASE_URL` at `https://api.search.brave.com` with a real Brave key
  /// to bypass Hack Club's proxy entirely.
  bool get _isBraveDirect => _baseUrl.contains('brave');

  Map<String, String> _authHeaders(String key) => _isBraveDirect
      ? <String, String>{
          'X-Subscription-Token': key,
          'Accept': 'application/json',
        }
      : <String, String>{
          'Authorization': 'Bearer $key',
          'Accept': 'application/json',
        };

  Future<List<SearchResult>> search(String query, {int count = 4}) async {
    final String key = _key;
    final String q = query.trim();
    if (key.isEmpty || key == _placeholderKey || q.isEmpty) {
      return const <SearchResult>[];
    }

    try {
      final Uri uri = Uri.parse(
        '$_baseUrl/res/v1/web/search',
      ).replace(queryParameters: <String, String>{'q': q, 'count': '$count'});
      final http.Response resp = await _client
          .get(uri, headers: _authHeaders(key))
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        // Status only, never the body (it can echo the query / upstream detail).
        AppLogger.warning('Search HTTP ${resp.statusCode}');
        return const <SearchResult>[];
      }

      final Object? decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) return const <SearchResult>[];
      final Object? web = decoded['web'];
      final List<dynamic> results = web is Map<String, dynamic>
          ? (web['results'] as List<dynamic>? ?? const <dynamic>[])
          : const <dynamic>[];

      final List<SearchResult> out = <SearchResult>[];
      for (final Object? item in results) {
        if (item is! Map) continue;
        final Map<String, dynamic> m = item.cast<String, dynamic>();
        final String title = _strip((m['title'] ?? '').toString());
        final String url = (m['url'] ?? '').toString();
        if (title.isEmpty || url.isEmpty) continue;
        out.add(
          SearchResult(
            title: title,
            description: _strip((m['description'] ?? '').toString()),
            url: url,
          ),
        );
        if (out.length >= count) break;
      }
      return out;
    } on Object catch (e, st) {
      AppLogger.warning('Search request failed', e, st);
      return const <SearchResult>[];
    }
  }

  /// Brave puts light HTML (`<strong>` highlights) in titles/descriptions.
  String _strip(String s) =>
      s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&amp;', '&').trim();
}

final searchServiceProvider = Provider<SearchService>((ref) {
  final http.Client client = http.Client();
  ref.onDispose(client.close);
  return SearchService(client);
});
