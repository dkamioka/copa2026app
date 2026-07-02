@Timeout(Duration(minutes: 3))
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup2026/data/football_data/football_data_config.dart';
import 'package:worldcup2026/data/football_data/football_data_repository.dart';
import 'package:worldcup2026/models/match.dart';

/// End-to-end validation of the football-data.org pipeline against the
/// REAL live 2026 World Cup feed. Assertions are structural (counts,
/// invariants) rather than result-pinned, since the tournament is in
/// progress and scores change daily.
///
///   flutter test test/football_data_integration_test.dart \
///     --dart-define=FOOTBALLDATA_TOKEN=your_token
///
/// Costs ~4 requests of the 10/min free-tier budget per run. The token
/// comes from the environment only — never hardcode it here.
void main() {
  test(
    'full pipeline against the live 2026 World Cup feed',
    skip: FootballDataConfig.enabled
        ? false
        : 'no FOOTBALLDATA_TOKEN/FOOTBALLDATA_PROXY configured',
    () async {
      final repo = FootballDataRepository();
      addTearDown(repo.dispose);

      await repo.refresh();

      // Bracket structure: the 2026 knockout from the R16 onwards.
      expect(repo.matchesByRound(Round.r16), hasLength(8));
      expect(repo.matchesByRound(Round.qf), hasLength(4));
      expect(repo.matchesByRound(Round.sf), hasLength(2));
      expect(repo.matchesByRound(Round.f), hasLength(1));

      // Team lookup coverage: every decided knockout slot must resolve
      // to a real entry, never the neutral fallback flag.
      for (final round in Round.values) {
        for (final match in repo.matchesByRound(round)) {
          if (match.teamA != null) {
            expect(match.flagA, isNot('🏳️'), reason: 'unmapped: ${match.nameA}');
          }
          if (match.teamB != null) {
            expect(match.flagB, isNot('🏳️'), reason: 'unmapped: ${match.nameB}');
          }
        }
      }

      // Standings: 12 groups of 4 in the 2026 format, PT-BR letters,
      // and (with the knockout already drawn) 2–3 qualified per group.
      final groups = repo.groupStandings;
      expect(groups, hasLength(12));
      for (final g in groups) {
        expect(g.letter, startsWith('Grupo'));
        expect(g.rows, hasLength(4));
        final qualified = g.rows.where((r) => r.qualified).length;
        expect(qualified, inInclusiveRange(2, 3),
            reason: '${g.letter}: top-2 + possibly a best-third advance');
      }
      // Across all 12 groups exactly 32 teams reached the knockout.
      final totalQualified = groups
          .expand((g) => g.rows)
          .where((r) => r.qualified)
          .length;
      expect(totalQualified, 32);

      // Scorers: non-empty, rank strictly ordered, goals descending.
      final scorers = repo.topScorers;
      expect(scorers, isNotEmpty);
      expect(scorers.first.rank, 1);
      for (var i = 1; i < scorers.length; i++) {
        expect(scorers[i].goals, lessThanOrEqualTo(scorers[i - 1].goals));
      }

      // Detail bundle for a decided R16 match: group campaign must
      // derive 3 games per team from the cached group fixtures.
      final decided = repo
          .matchesByRound(Round.r16)
          .where((m) => m.teamA != null && m.teamB != null)
          .toList();
      if (decided.isNotEmpty) {
        final detail = await repo.loadMatchDetail(decided.first);
        expect(detail.formA, isNotNull);
        expect(detail.formA!.games, hasLength(3));
        expect(detail.formB!.games, hasLength(3));
        expect(detail.formA!.groupLabel, isNotEmpty);
      }
    },
  );
}
