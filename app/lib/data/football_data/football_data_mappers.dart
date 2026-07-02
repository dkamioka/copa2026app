import '../../models/group_standing.dart';
import '../../models/head_to_head.dart';
import '../../models/match.dart';
import '../../models/match_event.dart';
import '../../models/penalty_shootout.dart';
import '../../models/scorer.dart';
import '../api_football/team_lookup.dart';

/// Pure JSON → domain-model mapping for football-data.org v4 responses.
/// Shapes verified against the live 2026 World Cup feed (see
/// test/football_data_mappers_test.dart for real-shape samples).
abstract final class FootballDataMappers {
  /// Maps a v4 `stage` to a bracket [Round]. LAST_32 and THIRD_PLACE are
  /// deliberately outside the bracket (same product decision as the
  /// API-Football adapter).
  static Round? roundFromStage(String? stage) => switch (stage) {
        'LAST_16' => Round.r16,
        'QUARTER_FINALS' => Round.qf,
        'SEMI_FINALS' => Round.sf,
        'FINAL' => Round.f,
        _ => null,
      };

  static int? _asInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _fmtShort(DateTime d) {
    final l = d.toLocal();
    return '${_two(l.day)}/${_two(l.month)} · ${_two(l.hour)}:${_two(l.minute)}';
  }

  static String _fmtLong(DateTime d) {
    final l = d.toLocal();
    return '${_two(l.day)}/${_two(l.month)}/${l.year} · ${_two(l.hour)}:${_two(l.minute)}';
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final l = d.toLocal();
    return '${_two(l.day)} ${months[l.month - 1]} ${l.year}';
  }

  static MatchStatus statusFrom(String? status) => switch (status) {
        'FINISHED' => MatchStatus.finished,
        'IN_PLAY' || 'PAUSED' => MatchStatus.live,
        _ => MatchStatus.upcoming,
      };

  /// Display score for a v4 `score` object. Subtle but critical: when a
  /// match went to a shootout, `fullTime` INCLUDES the penalty kicks
  /// (verified on real data: regularTime 1-1, penalties 3-4 →
  /// fullTime 4-5). The score people expect to see is regular + extra
  /// time only, with the shootout shown separately.
  static (int?, int?) displayScore(Map<String, dynamic> score) {
    final fullTime = score['fullTime'] as Map<String, dynamic>? ?? const {};
    if (score['duration'] == 'PENALTY_SHOOTOUT') {
      final reg = score['regularTime'] as Map<String, dynamic>? ?? const {};
      final ext = score['extraTime'] as Map<String, dynamic>? ?? const {};
      final regH = _asInt(reg['home']);
      final regA = _asInt(reg['away']);
      if (regH != null && regA != null) {
        return (regH + (_asInt(ext['home']) ?? 0), regA + (_asInt(ext['away']) ?? 0));
      }
    }
    return (_asInt(fullTime['home']), _asInt(fullTime['away']));
  }

  /// Builds a [Match] from one item of `/competitions/WC/matches`.
  static Match matchFromJson(Map<String, dynamic> json, Round round) {
    final home = json['homeTeam'] as Map<String, dynamic>? ?? const {};
    final away = json['awayTeam'] as Map<String, dynamic>? ?? const {};
    final score = json['score'] as Map<String, dynamic>? ?? const {};

    // Undecided slots (early knockout rounds) come as null team names.
    final homeName = home['name'] as String?;
    final awayName = away['name'] as String?;
    final teamA = homeName != null ? TeamLookup.resolve(homeName) : null;
    final teamB = awayName != null ? TeamLookup.resolve(awayName) : null;

    final status = statusFrom(json['status'] as String?);
    final (scoreA, scoreB) = displayScore(score);

    final penaltyMap = score['penalties'] as Map<String, dynamic>? ?? const {};
    final penA = _asInt(penaltyMap['home']);
    final penB = _asInt(penaltyMap['away']);
    PenaltyShootout? penalties;
    if (penA != null && penB != null) {
      penalties = PenaltyShootout(
        teamA: List.filled(penA, true),
        teamB: List.filled(penB, true),
        winner: penA >= penB ? MatchSide.a : MatchSide.b,
      );
    }

    final date = DateTime.tryParse(json['utcDate'] as String? ?? '') ?? DateTime(2026);

    return Match(
      id: '${json['id']}',
      round: round,
      teamA: teamA,
      teamB: teamB,
      status: status,
      scoreA: scoreA,
      scoreB: scoreB,
      // v4's match list carries no live minute — the UI hides the
      // minute when it's unknown.
      liveMinute: null,
      penalties: penalties,
      // v4's free tier doesn't populate venue either.
      venue: '',
      dateShort: _fmtShort(date),
      dateLong: _fmtLong(date),
    );
  }

  /// Builds group standings from `/competitions/WC/standings`.
  /// [qualifiedTeamNames] — resolved PT-BR names of every team that
  /// appears in a knockout fixture — marks who actually advanced (the
  /// 2026 format promotes the 8 best third-placed teams too, which a
  /// naive top-2 rule would miss). Falls back to top-2 while the
  /// knockout draw doesn't exist yet.
  static List<GroupStanding> standingsFromJson(
    Map<String, dynamic> json, {
    Set<String> qualifiedTeamNames = const {},
  }) {
    final standings = json['standings'];
    if (standings is! List) return const [];

    final out = <GroupStanding>[];
    for (final group in standings) {
      if (group is! Map<String, dynamic>) continue;
      if (group['type'] != 'TOTAL') continue;
      final table = group['table'];
      if (table is! List || table.isEmpty) continue;

      final letter = _ptGroup(group['group'] as String? ?? '');
      final rows = <GroupStandingRow>[];
      for (var i = 0; i < table.length; i++) {
        final row = table[i];
        if (row is! Map<String, dynamic>) continue;
        final teamMap = row['team'] as Map<String, dynamic>? ?? const {};
        final team = TeamLookup.resolve(teamMap['name'] as String? ?? '?');
        rows.add(GroupStandingRow(
          team: team,
          points: _asInt(row['points']) ?? 0,
          played: _asInt(row['playedGames']) ?? 0,
          wins: _asInt(row['won']) ?? 0,
          draws: _asInt(row['draw']) ?? 0,
          losses: _asInt(row['lost']) ?? 0,
          goalDiff: _asInt(row['goalDifference']) ?? 0,
          qualified: qualifiedTeamNames.isNotEmpty
              ? qualifiedTeamNames.contains(team.name)
              : i < 2,
        ));
      }
      if (rows.isNotEmpty) out.add(GroupStanding(letter: letter, rows: rows));
    }
    return out;
  }

  static List<Scorer> scorersFromJson(Map<String, dynamic> json) {
    final scorers = json['scorers'];
    if (scorers is! List) return const [];
    final out = <Scorer>[];
    for (final raw in scorers) {
      if (raw is! Map<String, dynamic>) continue;
      final player = raw['player'] as Map<String, dynamic>? ?? const {};
      final team = raw['team'] as Map<String, dynamic>? ?? const {};
      final name = player['name'] as String? ?? '?';
      out.add(Scorer(
        rank: out.length + 1,
        player: name,
        team: TeamLookup.resolve(
          team['name'] as String? ?? player['nationality'] as String? ?? '?',
        ),
        goals: _asInt(raw['goals']) ?? 0,
      ));
    }
    return out;
  }

  /// Maps `/matches/{id}/head2head` to display entries, most recent
  /// first.
  static List<HeadToHead> headToHeadFromJson(Map<String, dynamic> json, {int limit = 5}) {
    final matches = json['matches'];
    if (matches is! List) return const [];

    final entries = <(DateTime, HeadToHead)>[];
    for (final raw in matches) {
      if (raw is! Map<String, dynamic>) continue;
      final home = raw['homeTeam'] as Map<String, dynamic>? ?? const {};
      final away = raw['awayTeam'] as Map<String, dynamic>? ?? const {};
      final score = raw['score'] as Map<String, dynamic>? ?? const {};
      final competition = raw['competition'] as Map<String, dynamic>? ?? const {};
      final (gh, ga) = displayScore(score);
      if (gh == null || ga == null) continue;

      final flagH = TeamLookup.resolve(home['name'] as String? ?? '').flag;
      final flagA = TeamLookup.resolve(away['name'] as String? ?? '').flag;
      final date = DateTime.tryParse(raw['utcDate'] as String? ?? '') ?? DateTime(2000);
      entries.add((
        date,
        HeadToHead(
          fixture: '$flagH $gh – $ga $flagA',
          competition: competition['name'] as String? ?? '',
          date: _fmtDate(date),
        ),
      ));
    }
    entries.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final e in entries.take(limit)) e.$2];
  }

  /// Computes a team's group-stage result chips from the finished
  /// GROUP_STAGE matches it appeared in. [teamApiName] is the
  /// football-data name (e.g. "Brazil").
  static List<GroupFormGame> groupGames(
    String teamApiName,
    List<Map<String, dynamic>> groupMatches,
  ) {
    final games = <GroupFormGame>[];
    for (final json in groupMatches) {
      final home = json['homeTeam'] as Map<String, dynamic>? ?? const {};
      final away = json['awayTeam'] as Map<String, dynamic>? ?? const {};
      final score = json['score'] as Map<String, dynamic>? ?? const {};
      final homeName = home['name'] as String? ?? '';
      final awayName = away['name'] as String? ?? '';
      final (gh, ga) = displayScore(score);
      if (gh == null || ga == null) continue;

      final isHome = homeName == teamApiName;
      final isAway = awayName == teamApiName;
      if (!isHome && !isAway) continue;

      final own = isHome ? gh : ga;
      final opp = isHome ? ga : gh;
      final result = own > opp
          ? GameResult.win
          : own == opp
              ? GameResult.draw
              : GameResult.loss;
      games.add(GroupFormGame(
        result: result,
        score: '$own-$opp',
        opponent: TeamLookup.resolve(isHome ? awayName : homeName),
      ));
    }
    return games;
  }

  static String _ptGroup(String group) {
    // "GROUP_A" / "Group A" -> "Grupo A"
    final normalized = group.replaceAll('_', ' ');
    return normalized.replaceFirst(RegExp(r'^Group', caseSensitive: false), 'Grupo').trim();
  }
}
