import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:worldcup2026/data/api_football/api_football_client.dart';
import 'package:worldcup2026/data/api_football/api_football_repository.dart';
import 'package:worldcup2026/models/match.dart';

Map<String, dynamic> _fixture({
  required int id,
  required String round,
  String home = 'Brazil',
  String away = 'France',
  String status = 'FT',
}) =>
    {
      'fixture': {
        'id': id,
        'date': '2026-06-30T21:00:00+00:00',
        'status': {'short': status, 'elapsed': status == 'FT' ? 90 : 30},
        'venue': {'name': 'Stadium', 'city': 'City'},
      },
      'league': {'round': round},
      'teams': {
        'home': {'id': 1, 'name': home},
        'away': {'id': 2, 'name': away},
      },
      'goals': {'home': 1, 'away': 0},
      'score': {'penalty': {'home': null, 'away': null}},
    };

String _envelope(List<dynamic> response) => jsonEncode({
      'errors': [],
      'paging': {'current': 1, 'total': 1},
      'response': response,
    });

void main() {
  test('a failed detail fetch is retried on the next open (not cached)', () async {
    var failEvents = true;
    final mock = MockClient((request) async {
      final path = request.url.path;
      if (path.contains('fixtures/events')) {
        if (failEvents) return http.Response('boom', 500);
        return http.Response(
          _envelope([
            {
              'time': {'elapsed': 12},
              'team': {'name': 'Brazil'},
              'player': {'name': 'Raphinha'},
              'type': 'Goal',
              'detail': 'Normal Goal',
            },
          ]),
          200,
        );
      }
      if (path.contains('injuries') || path.contains('headtohead')) {
        return http.Response(_envelope([]), 200);
      }
      if (path.contains('fixtures')) {
        return http.Response(_envelope([_fixture(id: 100, round: 'Quarter-finals')]), 200);
      }
      // standings / topscorers
      return http.Response(_envelope([]), 200);
    });

    // TTL zero so the failed round-trip isn't masked by the client cache.
    final repo = ApiFootballRepository(
      client: ApiFootballClient(httpClient: mock, cacheTtl: Duration.zero),
    );
    await repo.refresh();
    final match = repo.matchesByRound(Round.qf).single;

    final failed = await repo.loadMatchDetail(match);
    expect(failed.events, isEmpty);

    failEvents = false;
    final retried = await repo.loadMatchDetail(match);
    expect(retried.events, hasLength(1), reason: 'a transient failure must not be cached');
    expect(retried.events.single.player, 'Raphinha');

    // And a successful load IS cached: flip the endpoint back to failing —
    // the cached detail should still be served.
    failEvents = true;
    final cached = await repo.loadMatchDetail(match);
    expect(cached.events, hasLength(1));
  });

  test('refresh routes knockout fixtures into rounds and finds the live match', () async {
    final mock = MockClient((request) async {
      if (request.url.path.contains('fixtures')) {
        return http.Response(
          _envelope([
            _fixture(id: 1, round: 'Round of 16'),
            _fixture(id: 2, round: 'Quarter-finals', status: '2H'),
            _fixture(id: 3, round: 'Round of 32'), // 2026 format — not in the bracket
            _fixture(id: 4, round: '3rd Place Final'),
          ]),
          200,
        );
      }
      return http.Response(_envelope([]), 200);
    });

    final repo = ApiFootballRepository(client: ApiFootballClient(httpClient: mock));
    await repo.refresh();

    expect(repo.matchesByRound(Round.r16), hasLength(1));
    expect(repo.matchesByRound(Round.qf), hasLength(1));
    expect(repo.matchesByRound(Round.f), isEmpty,
        reason: 'Round of 32 / 3rd place must not leak into the Final column');
    expect(repo.liveMatch?.id, '2');
  });
}
