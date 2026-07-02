import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ApiFootballException implements Exception {
  final String message;
  ApiFootballException(this.message);
  @override
  String toString() => 'ApiFootballException: $message';
}

/// Thin wrapper over the API-Football v3 REST endpoints.
///
/// Handles the standard response envelope (`{ response: [...], errors:
/// [...] }`), auth header, pagination, and a small in-memory TTL cache
/// so repeated reads (e.g. reopening the same match sheet) don't burn
/// the request quota.
class ApiFootballClient {
  ApiFootballClient({
    http.Client? httpClient,
    this.cacheTtl = const Duration(minutes: 2),
    this.requestTimeout = const Duration(seconds: 12),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration cacheTtl;

  /// Per-request deadline. Without one, a hung connection would leave
  /// callers (and the startup screen) waiting forever.
  final Duration requestTimeout;

  final Map<String, _CacheEntry> _cache = {};

  /// Pages fetched concurrently after page 1 reveals the total.
  static const int _maxPages = 50;

  /// Fetches every page of an endpoint, concatenating the `response`
  /// arrays. API-Football paginates at 20 items/page for large result
  /// sets (e.g. all fixtures of a tournament).
  Future<List<dynamic>> getAll(
    String path,
    Map<String, String> query, {
    DateTime Function()? now,
  }) async {
    final clock = now ?? DateTime.now;
    final cacheKey = '$path?${_stableQuery(query)}';
    final cached = _cache[cacheKey];
    if (cached != null && clock().isBefore(cached.expiresAt)) {
      return cached.value;
    }

    final all = <dynamic>[];
    final first = await _getRaw(path, {...query, 'page': '1'});
    final firstResponse = first['response'];
    if (firstResponse is List) all.addAll(firstResponse);

    final paging = first['paging'];
    final total = (paging is Map && paging['total'] is int) ? paging['total'] as int : 1;
    if (total > 1) {
      // Page 1 told us the total — fetch the rest concurrently instead
      // of one round-trip at a time (a full World Cup fixture list is
      // ~6 pages; sequential paging multiplies startup latency).
      final lastPage = total.clamp(1, _maxPages);
      final rest = await Future.wait([
        for (var page = 2; page <= lastPage; page++)
          _getRaw(path, {...query, 'page': '$page'}),
      ]);
      for (final json in rest) {
        final response = json['response'];
        if (response is List) all.addAll(response);
      }
    }

    // Stored (and returned) as unmodifiable so one caller can't mutate
    // what a later cache hit sees.
    final value = List<dynamic>.unmodifiable(all);
    _cache[cacheKey] = _CacheEntry(value, clock().add(cacheTtl));
    return value;
  }

  Future<Map<String, dynamic>> _getRaw(String path, Map<String, String> query) async {
    final uri = Uri.https(ApiConfig.host, '/$path', query);
    // In proxy mode the key lives server-side — send it only when
    // talking directly to api-sports.io (dev-with-key mode).
    final headers = ApiConfig.useProxy
        ? const <String, String>{}
        : {'x-apisports-key': ApiConfig.apiKey};
    late final http.Response res;
    try {
      res = await _http.get(uri, headers: headers).timeout(requestTimeout);
    } on TimeoutException {
      throw ApiFootballException('/$path timed out after ${requestTimeout.inSeconds}s');
    } catch (e) {
      throw ApiFootballException('Network error calling /$path: $e');
    }

    if (res.statusCode != 200) {
      throw ApiFootballException('/$path returned HTTP ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiFootballException('/$path returned an unexpected body');
    }

    // API-Football reports auth/quota/param problems in `errors`, which
    // can be either a list (ok/empty) or a map (problem).
    final errors = decoded['errors'];
    if (errors is Map && errors.isNotEmpty) {
      throw ApiFootballException('/$path error: ${jsonEncode(errors)}');
    }
    if (errors is List && errors.isNotEmpty) {
      throw ApiFootballException('/$path error: ${jsonEncode(errors)}');
    }
    return decoded;
  }

  static String _stableQuery(Map<String, String> query) {
    final keys = query.keys.toList()..sort();
    return keys.map((k) => '$k=${query[k]}').join('&');
  }

  void dispose() => _http.close();
}

class _CacheEntry {
  final List<dynamic> value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
}
