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
  ApiFootballClient({http.Client? httpClient, this.cacheTtl = const Duration(minutes: 2)})
      : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration cacheTtl;
  final Map<String, _CacheEntry> _cache = {};

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
    var page = 1;
    while (true) {
      final json = await _getRaw(path, {...query, 'page': '$page'});
      final response = json['response'];
      if (response is List) all.addAll(response);

      final paging = json['paging'];
      final total = (paging is Map && paging['total'] is int) ? paging['total'] as int : 1;
      if (page >= total) break;
      page++;
      if (page > 50) break; // hard safety cap against a runaway paging loop
    }

    _cache[cacheKey] = _CacheEntry(all, clock().add(cacheTtl));
    return all;
  }

  Future<Map<String, dynamic>> _getRaw(String path, Map<String, String> query) async {
    final uri = Uri.https(ApiConfig.host, '/$path', query);
    late final http.Response res;
    try {
      res = await _http.get(uri, headers: {'x-apisports-key': ApiConfig.apiKey});
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
