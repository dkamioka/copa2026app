import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'football_data_config.dart';

class FootballDataException implements Exception {
  final String message;
  FootballDataException(this.message);
  @override
  String toString() => 'FootballDataException: $message';
}

/// Thin wrapper over the football-data.org v4 REST endpoints: auth
/// header, per-request timeout, error mapping, and a small in-memory
/// TTL cache so repeated reads don't burn the 10-requests/minute
/// free-tier budget.
class FootballDataClient {
  FootballDataClient({
    http.Client? httpClient,
    this.cacheTtl = const Duration(minutes: 2),
    this.requestTimeout = const Duration(seconds: 12),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration cacheTtl;
  final Duration requestTimeout;
  final Map<String, _CacheEntry> _cache = {};

  /// GETs `<basePath>/<path>` and returns the decoded JSON object.
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    DateTime Function()? now,
  }) async {
    final clock = now ?? DateTime.now;
    final uri = Uri.https(
      FootballDataConfig.host,
      '${FootballDataConfig.basePath}/$path',
      query,
    );
    final cacheKey = uri.toString();
    final cached = _cache[cacheKey];
    if (cached != null && clock().isBefore(cached.expiresAt)) {
      return cached.value;
    }

    // In proxy mode the token lives server-side.
    final headers = FootballDataConfig.useProxy
        ? const <String, String>{}
        : {'X-Auth-Token': FootballDataConfig.token};

    late final http.Response res;
    try {
      res = await _http.get(uri, headers: headers).timeout(requestTimeout);
    } on TimeoutException {
      throw FootballDataException('/$path timed out after ${requestTimeout.inSeconds}s');
    } catch (e) {
      throw FootballDataException('Network error calling /$path: $e');
    }

    if (res.statusCode == 429) {
      throw FootballDataException('/$path rate-limited (free tier: 10 req/min)');
    }
    if (res.statusCode != 200) {
      throw FootballDataException('/$path returned HTTP ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw FootballDataException('/$path returned an unexpected body');
    }
    // v4 reports problems as {message, errorCode} even on some 200s.
    if (decoded['errorCode'] != null) {
      throw FootballDataException('/$path error: ${decoded['message']}');
    }

    _cache[cacheKey] = _CacheEntry(decoded, clock().add(cacheTtl));
    return decoded;
  }

  void dispose() => _http.close();
}

class _CacheEntry {
  final Map<String, dynamic> value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
}
