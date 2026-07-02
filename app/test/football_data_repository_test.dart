import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:worldcup2026/data/football_data/football_data_client.dart';
import 'package:worldcup2026/data/football_data/football_data_repository.dart';
import 'package:worldcup2026/models/match.dart';

Map<String, dynamic> _match({
  required int id,
  required String stage,
  String? home,
  String? away,
  String status = 'TIMED',
  String utcDate = '2026-07-04T20:00:00Z',
  int? scoreHome,
  int? scoreAway,
}) =>
    {
      'id': id,
      'stage': stage,
      'status': status,
      'utcDate': utcDate,
      'homeTeam': {'name': home},
      'awayTeam': {'name': away},
      'score': {
        'fullTime': {'home': scoreHome, 'away': scoreAway},
      },
    };

void main() {
  test('knockout rounds come out in bracket order, not kickoff order', () async {
    // Real 2026 shape, reduced: 4 R32 games in a kickoff order that
    // does NOT match the bracket, feeding 2 R16 fixtures whose slots
    // are known because the feeders finished. Bracket linkage:
    //   R16 #1: Paraguay (won g4) x France (won g2)
    //   R16 #2: Brazil  (won g1) x Norway (won g3)
    final matches = [
      _match(id: 1, stage: 'LAST_32', home: 'Brazil', away: 'Japan', status: 'FINISHED', utcDate: '2026-06-29T17:00:00Z', scoreHome: 2, scoreAway: 0),
      _match(id: 2, stage: 'LAST_32', home: 'France', away: 'Sweden', status: 'FINISHED', utcDate: '2026-06-30T21:00:00Z', scoreHome: 3, scoreAway: 1),
      _match(id: 3, stage: 'LAST_32', home: 'Ivory Coast', away: 'Norway', status: 'FINISHED', utcDate: '2026-06-30T17:00:00Z', scoreHome: 0, scoreAway: 1),
      _match(id: 4, stage: 'LAST_32', home: 'Germany', away: 'Paraguay', status: 'FINISHED', utcDate: '2026-06-29T20:30:00Z', scoreHome: 0, scoreAway: 1),
      _match(id: 5, stage: 'LAST_16', home: 'Paraguay', away: 'France', utcDate: '2026-07-04T21:00:00Z'),
      _match(id: 6, stage: 'LAST_16', home: 'Brazil', away: 'Norway', utcDate: '2026-07-05T20:00:00Z'),
    ];

    final mock = MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/matches')) {
        return http.Response(jsonEncode({'matches': matches}), 200);
      }
      if (path.endsWith('/standings')) {
        return http.Response(jsonEncode({'standings': []}), 200);
      }
      return http.Response(jsonEncode({'scorers': []}), 200);
    });

    final repo = FootballDataRepository(
      client: FootballDataClient(httpClient: mock),
    );
    await repo.refresh();

    final r32 = repo.matchesByRound(Round.r32);
    expect(r32, hasLength(4));
    // Feeders adjacent to their R16 slot, home-side feeder first:
    // (Paraguay, France) then (Brazil, Norway).
    expect(r32[0].nameB, 'Paraguai');
    expect(r32[1].nameA, 'França');
    expect(r32[2].nameA, 'Brasil');
    expect(r32[3].nameB, 'Noruega');
    expect(repo.lastUpdatedAt, isNotNull);
  });
}
