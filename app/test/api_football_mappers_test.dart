import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup2026/data/api_football/api_football_mappers.dart';
import 'package:worldcup2026/models/match.dart';
import 'package:worldcup2026/models/match_event.dart';

void main() {
  group('roundFromLabel', () {
    test('maps knockout labels to bracket rounds', () {
      expect(ApiFootballMappers.roundFromLabel('8th Finals'), Round.r16);
      expect(ApiFootballMappers.roundFromLabel('Round of 16'), Round.r16);
      expect(ApiFootballMappers.roundFromLabel('Quarter-finals'), Round.qf);
      expect(ApiFootballMappers.roundFromLabel('Semi-finals'), Round.sf);
      expect(ApiFootballMappers.roundFromLabel('Final'), Round.f);
    });

    test('returns null for group stage and 3rd-place match', () {
      expect(ApiFootballMappers.roundFromLabel('Group Stage - 1'), isNull);
      expect(ApiFootballMappers.roundFromLabel('3rd Place Final'), isNull);
    });
  });

  test('matchFromFixture parses a finished match decided on penalties', () {
    final json = {
      'fixture': {
        'id': 12345,
        'date': '2026-06-30T21:00:00+00:00',
        'status': {'long': 'Match Finished', 'short': 'PEN', 'elapsed': 120},
        'venue': {'name': 'Mercedes-Benz Stadium', 'city': 'Atlanta'},
      },
      'league': {'round': 'Quarter-finals'},
      'teams': {
        'home': {'id': 6, 'name': 'Brazil'},
        'away': {'id': 2, 'name': 'France'},
      },
      'goals': {'home': 1, 'away': 1},
      'score': {
        'penalty': {'home': 4, 'away': 2},
      },
    };

    final match = ApiFootballMappers.matchFromFixture(json, Round.qf);

    expect(match.id, '12345');
    expect(match.teamA?.name, 'Brasil');
    expect(match.teamB?.name, 'França');
    expect(match.isFinished, isTrue);
    expect(match.scoreA, 1);
    expect(match.scoreB, 1);
    expect(match.penalties, isNotNull);
    expect(match.penalties!.scoreA, 4);
    expect(match.penalties!.scoreB, 2);
    expect(match.winner, MatchSide.a);
    expect(match.venue, 'Mercedes-Benz Stadium, Atlanta');
  });

  test('matchFromFixture parses a live match with elapsed minute', () {
    final json = {
      'fixture': {
        'id': 999,
        'date': '2026-07-01T18:00:00+00:00',
        'status': {'short': '2H', 'elapsed': 67},
        'venue': {'name': 'Hard Rock Stadium', 'city': 'Miami'},
      },
      'league': {'round': 'Quarter-finals'},
      'teams': {
        'home': {'id': 26, 'name': 'Argentina'},
        'away': {'id': 9, 'name': 'Spain'},
      },
      'goals': {'home': 1, 'away': 1},
      'score': {'penalty': {'home': null, 'away': null}},
    };

    final match = ApiFootballMappers.matchFromFixture(json, Round.qf);
    expect(match.isLive, isTrue);
    expect(match.liveMinute, "67'");
    expect(match.penalties, isNull);
  });

  test('eventsFromJson maps goals/cards to the correct side and ignores subs', () {
    final response = [
      {
        'time': {'elapsed': 23},
        'team': {'name': 'Brazil'},
        'player': {'name': 'Vinícius Jr'},
        'type': 'Goal',
        'detail': 'Normal Goal',
      },
      {
        'time': {'elapsed': 58},
        'team': {'name': 'France'},
        'player': {'name': 'Mbappé'},
        'type': 'Goal',
        'detail': 'Penalty',
      },
      {
        'time': {'elapsed': 84},
        'team': {'name': 'France'},
        'player': {'name': 'Mendy'},
        'type': 'Card',
        'detail': 'Red Card',
      },
      {
        'time': {'elapsed': 70},
        'team': {'name': 'Brazil'},
        'player': {'name': 'Someone'},
        'type': 'subst',
        'detail': 'Substitution 1',
      },
    ];

    final events = ApiFootballMappers.eventsFromJson(response, 'Brazil');
    expect(events.length, 3); // subst ignored
    expect(events.first.minute, 23);
    expect(events.first.side, MatchSide.a); // Brazil is home
    expect(events[1].type, MatchEventType.penaltyGoal);
    expect(events[1].side, MatchSide.b); // France is away
    expect(events[2].type, MatchEventType.redCard);
  });

  test('standingsFromJson builds groups and flags top-2 as qualified', () {
    final response = [
      {
        'league': {
          'standings': [
            [
              {
                'rank': 1,
                'team': {'name': 'Brazil'},
                'points': 9,
                'goalsDiff': 6,
                'group': 'Group A',
                'all': {'played': 3, 'win': 3, 'draw': 0, 'lose': 0},
              },
              {
                'rank': 2,
                'team': {'name': 'Mexico'},
                'points': 6,
                'goalsDiff': 2,
                'group': 'Group A',
                'all': {'played': 3, 'win': 2, 'draw': 0, 'lose': 1},
              },
              {
                'rank': 3,
                'team': {'name': 'Serbia'},
                'points': 3,
                'goalsDiff': -3,
                'group': 'Group A',
                'all': {'played': 3, 'win': 1, 'draw': 0, 'lose': 2},
              },
            ],
          ],
        },
      },
    ];

    final groups = ApiFootballMappers.standingsFromJson(response);
    expect(groups.length, 1);
    expect(groups.first.letter, 'Grupo A');
    expect(groups.first.rows.length, 3);
    expect(groups.first.rows[0].team.name, 'Brasil');
    expect(groups.first.rows[0].qualified, isTrue);
    expect(groups.first.rows[2].qualified, isFalse);
    expect(groups.first.rows[0].goalDiffLabel, '+6');
  });

  test('scorersFromJson ranks players by response order', () {
    final response = [
      {
        'player': {'name': 'Kylian Mbappé', 'nationality': 'France'},
        'statistics': [
          {'goals': {'total': 6}},
        ],
      },
      {
        'player': {'name': 'Harry Kane', 'nationality': 'England'},
        'statistics': [
          {'goals': {'total': 5}},
        ],
      },
    ];

    final scorers = ApiFootballMappers.scorersFromJson(response);
    expect(scorers.length, 2);
    expect(scorers[0].rank, 1);
    expect(scorers[0].player, 'Kylian Mbappé');
    expect(scorers[0].team.name, 'França');
    expect(scorers[0].goals, 6);
    expect(scorers[1].rank, 2);
  });

  test('headToHeadFromJson sorts most-recent first and respects limit', () {
    final response = [
      {
        'fixture': {'date': '2018-07-01T00:00:00+00:00'},
        'league': {'name': 'Friendly'},
        'teams': {
          'home': {'name': 'Brazil'},
          'away': {'name': 'France'},
        },
        'goals': {'home': 1, 'away': 0},
      },
      {
        'fixture': {'date': '2024-06-01T00:00:00+00:00'},
        'league': {'name': 'World Cup'},
        'teams': {
          'home': {'name': 'France'},
          'away': {'name': 'Brazil'},
        },
        'goals': {'home': 2, 'away': 2},
      },
    ];

    final h2h = ApiFootballMappers.headToHeadFromJson(response, limit: 1);
    expect(h2h.length, 1);
    expect(h2h.first.competition, 'World Cup'); // 2024 is more recent
  });

  test('teamNewsFromInjuries splits by team and picks suspension icons', () {
    final response = [
      {
        'player': {'name': 'Mendy', 'reason': 'Red Card'},
        'team': {'name': 'France'},
      },
      {
        'player': {'name': 'Casemiro', 'reason': 'Yellow Cards'},
        'team': {'name': 'Brazil'},
      },
      {
        'player': {'name': 'Dembélé', 'reason': 'Injury'},
        'team': {'name': 'France'},
      },
    ];

    final (home, away) =
        ApiFootballMappers.teamNewsFromInjuries(response, 'Brazil', 'France');
    expect(home.length, 1);
    expect(home.first.icon, '🟨');
    expect(away.length, 2);
    expect(away[0].icon, '🟥');
    expect(away[1].icon, '➕');
  });
}
