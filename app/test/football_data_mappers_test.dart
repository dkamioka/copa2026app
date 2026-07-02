import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup2026/data/football_data/football_data_mappers.dart';
import 'package:worldcup2026/models/match.dart';
import 'package:worldcup2026/models/match_event.dart';

/// Sample shapes mirror REAL football-data.org v4 responses captured
/// from the live 2026 World Cup feed.
void main() {
  group('roundFromStage', () {
    test('maps knockout stages to bracket rounds', () {
      expect(FootballDataMappers.roundFromStage('LAST_16'), Round.r16);
      expect(FootballDataMappers.roundFromStage('QUARTER_FINALS'), Round.qf);
      expect(FootballDataMappers.roundFromStage('SEMI_FINALS'), Round.sf);
      expect(FootballDataMappers.roundFromStage('FINAL'), Round.f);
    });

    test('maps the 2026 Round of 32 into the bracket', () {
      expect(FootballDataMappers.roundFromStage('LAST_32'), Round.r32);
    });

    test('keeps group stage and 3rd place out of the bracket', () {
      expect(FootballDataMappers.roundFromStage('GROUP_STAGE'), isNull);
      expect(FootballDataMappers.roundFromStage('THIRD_PLACE'), isNull);
    });
  });

  test('displayScore excludes shootout kicks from the full-time score', () {
    // Real shape: fullTime INCLUDES penalty kicks when the match went
    // to a shootout (regular 1-1 + pens 3-4 → fullTime 4-5).
    final score = {
      'winner': 'AWAY_TEAM',
      'duration': 'PENALTY_SHOOTOUT',
      'fullTime': {'home': 4, 'away': 5},
      'halfTime': {'home': 0, 'away': 1},
      'regularTime': {'home': 1, 'away': 1},
      'extraTime': {'home': 0, 'away': 0},
      'penalties': {'home': 3, 'away': 4},
    };
    final (a, b) = FootballDataMappers.displayScore(score);
    expect((a, b), (1, 1));
  });

  test('matchFromJson maps a finished shootout match', () {
    final json = {
      'id': 537400,
      'utcDate': '2026-06-29T20:00:00Z',
      'status': 'FINISHED',
      'stage': 'LAST_16',
      'homeTeam': {'id': 1, 'name': 'Brazil', 'tla': 'BRA'},
      'awayTeam': {'id': 2, 'name': 'France', 'tla': 'FRA'},
      'score': {
        'winner': 'AWAY_TEAM',
        'duration': 'PENALTY_SHOOTOUT',
        'fullTime': {'home': 4, 'away': 5},
        'regularTime': {'home': 1, 'away': 1},
        'extraTime': {'home': 0, 'away': 0},
        'penalties': {'home': 3, 'away': 4},
      },
    };

    final match = FootballDataMappers.matchFromJson(json, Round.r16);
    expect(match.id, '537400');
    expect(match.teamA?.name, 'Brasil');
    expect(match.teamB?.name, 'França');
    expect(match.isFinished, isTrue);
    expect(match.scoreA, 1);
    expect(match.scoreB, 1);
    expect(match.penalties!.scoreA, 3);
    expect(match.penalties!.scoreB, 4);
    expect(match.winner, MatchSide.b);
  });

  test('matchFromJson handles undecided slots (null teams)', () {
    final json = {
      'id': 537490,
      'utcDate': '2026-07-14T20:00:00Z',
      'status': 'TIMED',
      'stage': 'SEMI_FINALS',
      'homeTeam': {'id': null, 'name': null, 'tla': null},
      'awayTeam': {'id': null, 'name': null, 'tla': null},
      'score': {
        'winner': null,
        'duration': 'REGULAR',
        'fullTime': {'home': null, 'away': null},
      },
    };

    final match = FootballDataMappers.matchFromJson(json, Round.sf);
    expect(match.isTbd, isTrue);
    expect(match.nameA, 'A definir');
    expect(match.status, MatchStatus.upcoming);
  });

  test('statusFrom maps live states', () {
    expect(FootballDataMappers.statusFrom('IN_PLAY'), MatchStatus.live);
    expect(FootballDataMappers.statusFrom('PAUSED'), MatchStatus.live);
    expect(FootballDataMappers.statusFrom('FINISHED'), MatchStatus.finished);
    expect(FootballDataMappers.statusFrom('TIMED'), MatchStatus.upcoming);
    expect(FootballDataMappers.statusFrom('SCHEDULED'), MatchStatus.upcoming);
  });

  test('standingsFromJson maps groups and marks qualification by knockout presence', () {
    final json = {
      'standings': [
        {
          'stage': 'GROUP_STAGE',
          'type': 'TOTAL',
          'group': 'Group A',
          'table': [
            {
              'position': 1,
              'team': {'name': 'Mexico'},
              'playedGames': 3,
              'won': 3,
              'draw': 0,
              'lost': 0,
              'points': 9,
              'goalDifference': 6,
            },
            {
              'position': 2,
              'team': {'name': 'Sweden'},
              'playedGames': 3,
              'won': 1,
              'draw': 1,
              'lost': 1,
              'points': 4,
              'goalDifference': 0,
            },
            {
              'position': 3,
              'team': {'name': 'Turkey'},
              'playedGames': 3,
              'won': 1,
              'draw': 1,
              'lost': 1,
              'points': 4,
              'goalDifference': -1,
            },
            {
              'position': 4,
              'team': {'name': 'Haiti'},
              'playedGames': 3,
              'won': 0,
              'draw': 0,
              'lost': 3,
              'points': 0,
              'goalDifference': -5,
            },
          ],
        },
      ],
    };

    // Third-placed Turkey advanced as one of the 8 best thirds.
    final groups = FootballDataMappers.standingsFromJson(
      json,
      qualifiedTeamNames: {'México', 'Suécia', 'Turquia'},
    );
    expect(groups, hasLength(1));
    expect(groups.first.letter, 'Grupo A');
    expect(groups.first.rows.map((r) => r.qualified).toList(),
        [true, true, true, false]);
    expect(groups.first.rows[0].team.name, 'México');
  });

  test('scorersFromJson maps players with team resolution', () {
    final json = {
      'scorers': [
        {
          'player': {'name': 'Kylian Mbappé', 'nationality': 'France'},
          'team': {'name': 'France'},
          'playedMatches': 5,
          'goals': 6,
          'assists': 2,
          'penalties': null,
        },
      ],
    };
    final scorers = FootballDataMappers.scorersFromJson(json);
    expect(scorers.single.rank, 1);
    expect(scorers.single.player, 'Kylian Mbappé');
    expect(scorers.single.team.name, 'França');
    expect(scorers.single.goals, 6);
  });

  test('headToHeadFromJson orders most recent first', () {
    final json = {
      'matches': [
        {
          'utcDate': '2018-07-01T00:00:00Z',
          'homeTeam': {'name': 'Brazil'},
          'awayTeam': {'name': 'France'},
          'score': {'duration': 'REGULAR', 'fullTime': {'home': 1, 'away': 0}},
          'competition': {'name': 'Friendly'},
        },
        {
          'utcDate': '2026-06-28T00:00:00Z',
          'homeTeam': {'name': 'France'},
          'awayTeam': {'name': 'Brazil'},
          'score': {'duration': 'REGULAR', 'fullTime': {'home': 2, 'away': 2}},
          'competition': {'name': 'FIFA World Cup'},
        },
      ],
    };
    final h2h = FootballDataMappers.headToHeadFromJson(json);
    expect(h2h, hasLength(2));
    expect(h2h.first.competition, 'FIFA World Cup');
  });

  test('groupGames derives campaign chips from finished group matches', () {
    final matches = [
      {
        'homeTeam': {'name': 'Brazil'},
        'awayTeam': {'name': 'Morocco'},
        'score': {'duration': 'REGULAR', 'fullTime': {'home': 2, 'away': 0}},
      },
      {
        'homeTeam': {'name': 'Scotland'},
        'awayTeam': {'name': 'Brazil'},
        'score': {'duration': 'REGULAR', 'fullTime': {'home': 1, 'away': 1}},
      },
      {
        'homeTeam': {'name': 'Haiti'},
        'awayTeam': {'name': 'Morocco'},
        'score': {'duration': 'REGULAR', 'fullTime': {'home': 0, 'away': 3}},
      },
    ];
    final games = FootballDataMappers.groupGames('Brazil', matches);
    expect(games, hasLength(2));
    expect(games[0].score, '2-0');
    expect(games[0].opponent.name, 'Marrocos');
    expect(games[1].score, '1-1');
  });
}
