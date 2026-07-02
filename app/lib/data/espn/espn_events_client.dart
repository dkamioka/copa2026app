import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class EspnException implements Exception {
  final String message;
  EspnException(this.message);
  @override
  String toString() => 'EspnException: $message';
}

/// Keyless, unofficial ESPN endpoints used ONLY to fill the per-match
/// goal/card timeline that football-data.org's free tier doesn't
/// provide. Scores, standings and fixtures stay on football-data — if
/// ESPN changes or blocks these endpoints the app quietly falls back
/// to the "no timeline" note, nothing else degrades.
class EspnEventsClient {
  EspnEventsClient({
    http.Client? httpClient,
    this.requestTimeout = const Duration(seconds: 8),
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final Duration requestTimeout;

  static const _host = 'site.api.espn.com';
  static const _basePath = '/apis/site/v2/sports/soccer/fifa.world';

  /// The day's World Cup fixtures ([utcDay] in UTC).
  Future<Map<String, dynamic>> scoreboard(DateTime utcDay) {
    final d = utcDay.toUtc();
    final ymd = '${d.year}'
        '${d.month.toString().padLeft(2, '0')}'
        '${d.day.toString().padLeft(2, '0')}';
    return _getJson('scoreboard', {'dates': ymd});
  }

  /// Full match detail (timeline in `keyEvents`) for an ESPN event id.
  Future<Map<String, dynamic>> summary(String eventId) =>
      _getJson('summary', {'event': eventId});

  Future<Map<String, dynamic>> _getJson(String path, Map<String, String> query) async {
    final uri = Uri.https(_host, '$_basePath/$path', query);
    late final http.Response res;
    try {
      res = await _http.get(uri).timeout(requestTimeout);
    } on TimeoutException {
      throw EspnException('/$path timed out after ${requestTimeout.inSeconds}s');
    } catch (e) {
      throw EspnException('Network error calling /$path: $e');
    }
    if (res.statusCode != 200) {
      throw EspnException('/$path returned HTTP ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw EspnException('/$path returned an unexpected shape');
    }
    return decoded;
  }

  void dispose() => _http.close();
}
