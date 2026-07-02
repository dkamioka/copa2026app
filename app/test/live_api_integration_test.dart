@Timeout(Duration(minutes: 3))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup2026/data/api_football/api_config.dart';
import 'package:worldcup2026/data/api_football/api_football_repository.dart';
import 'package:worldcup2026/models/match.dart';
import 'package:worldcup2026/models/match_event.dart';

/// End-to-end validation of the live data pipeline (client → mappers →
/// repository) against the REAL API-Football service.
///
/// Skipped unless a key is provided — free-tier keys can only read
/// seasons 2022–2024, so QA runs point at the completed 2022 World Cup,
/// whose data is stable and fully known:
///
///   flutter test test/live_api_integration_test.dart \
///     --dart-define=APIFOOTBALL_KEY=your_key \
///     --dart-define=APIFOOTBALL_SEASON=2022
///
/// Costs ~6 requests of the daily quota per run. The key comes from the
/// environment only — never hardcode it here.
void main() {
  final hasKey = ApiConfig.apiKey.isNotEmpty || ApiConfig.useProxy;
  final is2022 = ApiConfig.season == 2022;

  test(
    'full pipeline against the real 2022 World Cup dataset',
    skip: !hasKey
        ? 'no APIFOOTBALL_KEY/APIFOOTBALL_PROXY configured'
        : !is2022
            ? 'assertions are pinned to season 2022 — pass --dart-define=APIFOOTBALL_SEASON=2022'
            : false,
    () async {
      final repo = ApiFootballRepository();
      addTearDown(repo.dispose);

      await repo.refresh();

      // Bracket: the completed knockout tree.
      expect(repo.matchesByRound(Round.r16), hasLength(8));
      expect(repo.matchesByRound(Round.qf), hasLength(4));
      expect(repo.matchesByRound(Round.sf), hasLength(2));
      expect(repo.matchesByRound(Round.f), hasLength(1));
      expect(repo.liveMatch, isNull, reason: '2022 has no live match');

      // Team lookup coverage: every knockout team must resolve to a
      // real entry (flag + PT-BR name), never the neutral fallback.
      for (final round in Round.values) {
        for (final match in repo.matchesByRound(round)) {
          expect(match.flagA, isNot('🏳️'),
              reason: 'unmapped team: ${match.nameA}');
          expect(match.flagB, isNot('🏳️'),
              reason: 'unmapped team: ${match.nameB}');
        }
      }

      // Standings: 8 groups, PT-BR letters, qualification flags from the
      // API's own description field.
      final groups = repo.groupStandings;
      expect(groups, hasLength(8));
      expect(groups.first.letter, startsWith('Grupo'));
      for (final g in groups) {
        expect(g.rows, hasLength(4));
        expect(g.rows.where((r) => r.qualified), hasLength(2),
            reason: 'exactly two advanced from ${g.letter} in 2022');
      }

      // Scorers: Mbappé won the 2022 golden boot with 8 goals.
      final scorers = repo.topScorers;
      expect(scorers, isNotEmpty);
      expect(scorers.first.rank, 1);
      expect(scorers.first.player, contains('Mbapp'));
      expect(scorers.first.goals, 8);
      expect(scorers.first.team.name, 'França');

      // The final (Argentina 3-3 France, 4-2 on penalties): status,
      // shootout mapping, and the lazy detail bundle end-to-end.
      final theFinal = repo.matchesByRound(Round.f).single;
      expect(theFinal.isFinished, isTrue);
      expect(theFinal.teamA?.name, 'Argentina');
      expect(theFinal.teamB?.name, 'França');
      expect(theFinal.scoreA, 3);
      expect(theFinal.scoreB, 3);
      expect(theFinal.penalties, isNotNull);
      expect(theFinal.penalties!.scoreA, 4);
      expect(theFinal.penalties!.scoreB, 2);
      expect(theFinal.winner, MatchSide.a);

      final detail = await repo.loadMatchDetail(theFinal);
      expect(detail.events, isNotEmpty,
          reason: 'the final had 6 goals in regular+extra time');
      expect(detail.events.where((e) => e.type == MatchEventType.goal ||
          e.type == MatchEventType.penaltyGoal), isNotEmpty);
      expect(detail.formA, isNotNull);
      expect(detail.formA!.games, hasLength(3),
          reason: 'group campaign derives from cached group fixtures');
      expect(detail.formB!.games, hasLength(3));
      expect(detail.formA!.groupLabel, isNotEmpty);
    },
  );
}
