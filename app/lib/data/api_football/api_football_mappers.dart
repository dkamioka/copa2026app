import '../../models/group_standing.dart';
import '../../models/head_to_head.dart';
import '../../models/match.dart';
import '../../models/match_event.dart';
import '../../models/penalty_shootout.dart';
import '../../models/scorer.dart';
import 'team_lookup.dart';

/// Pure JSON → domain-model mapping for API-Football v3 responses. Kept
/// free of any I/O so it can be unit-tested against sample payloads
/// without a live key (see test/api_football_mappers_test.dart).
abstract final class ApiFootballMappers {
  static const _liveStatuses = {'1H', '2H', 'HT', 'ET', 'BT', 'P', 'LIVE', 'INT', 'SUSP'};
  static const _finishedStatuses = {'FT', 'AET', 'PEN'};

  /// Maps an API round label ("8th Finals", "Quarter-finals", …) to a
  /// bracket [Round]. Returns null for the group stage and 3rd-place
  /// match, which the knockout bracket doesn't show.
  static Round? roundFromLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('8th') || l.contains('round of 16') || l.contains('1/8')) return Round.r16;
    if (l.contains('quarter')) return Round.qf;
    if (l.contains('semi')) return Round.sf;
    if (l.contains('3rd') || l.contains('third')) return null;
    if (l.contains('final')) return Round.f;
    return null;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _fmtShort(DateTime d) {
    final l = d.toLocal();
    return '${_two(l.day)}/${_two(l.month)} · ${_two(l.hour)}:${_two(l.minute)}';
  }

  static String _fmtLong(DateTime d) {
    final l = d.toLocal();
    return '${_two(l.day)}/${_two(l.month)}/${l.year} · ${_two(l.hour)}:${_two(l.minute)}';
  }

  static MatchStatus _status(String short) {
    if (_finishedStatuses.contains(short)) return MatchStatus.finished;
    if (_liveStatuses.contains(short)) return MatchStatus.live;
    return MatchStatus.upcoming;
  }

  static int? _asInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);

  /// Builds a [Match] from one `/fixtures` response item. Only meaningful
  /// for knockout fixtures; [round] is the resolved bracket round.
  static Match matchFromFixture(Map<String, dynamic> json, Round round) {
    final fixture = json['fixture'] as Map<String, dynamic>;
    final teams = json['teams'] as Map<String, dynamic>;
    final goals = json['goals'] as Map<String, dynamic>? ?? const {};
    final score = json['score'] as Map<String, dynamic>? ?? const {};

    final home = teams['home'] as Map<String, dynamic>;
    final away = teams['away'] as Map<String, dynamic>;
    final teamA = TeamLookup.resolve(home['name'] as String? ?? 'A definir');
    final teamB = TeamLookup.resolve(away['name'] as String? ?? 'A definir');

    final statusMap = fixture['status'] as Map<String, dynamic>? ?? const {};
    final short = statusMap['short'] as String? ?? 'NS';
    final status = _status(short);
    final elapsed = _asInt(statusMap['elapsed']);

    final date = DateTime.tryParse(fixture['date'] as String? ?? '') ?? DateTime(2026);
    final venueMap = fixture['venue'] as Map<String, dynamic>? ?? const {};
    final venueName = venueMap['name'] as String?;
    final venueCity = venueMap['city'] as String?;
    final venue = [venueName, venueCity].where((s) => s != null && s.isNotEmpty).join(', ');

    final penaltyMap = score['penalty'] as Map<String, dynamic>? ?? const {};
    final penA = _asInt(penaltyMap['home']);
    final penB = _asInt(penaltyMap['away']);
    PenaltyShootout? penalties;
    if (penA != null && penB != null) {
      // API-Football exposes only the shootout totals, not the
      // kick-by-kick sequence, so we render one "scored" marker per goal.
      penalties = PenaltyShootout(
        teamA: List.filled(penA, true),
        teamB: List.filled(penB, true),
        winner: penA >= penB ? MatchSide.a : MatchSide.b,
      );
    }

    return Match(
      id: '${fixture['id']}',
      round: round,
      teamA: teamA,
      teamB: teamB,
      status: status,
      scoreA: _asInt(goals['home']),
      scoreB: _asInt(goals['away']),
      liveMinute: elapsed != null ? "$elapsed'" : null,
      penalties: penalties,
      venue: venue.isEmpty ? 'Local a definir' : venue,
      dateShort: _fmtShort(date),
      dateLong: _fmtLong(date),
    );
  }

  static List<MatchEvent> eventsFromJson(List<dynamic> response, String homeName) {
    final out = <MatchEvent>[];
    for (final raw in response) {
      if (raw is! Map<String, dynamic>) continue;
      final type = raw['type'] as String? ?? '';
      final detail = raw['detail'] as String? ?? '';
      final time = raw['time'] as Map<String, dynamic>? ?? const {};
      final minute = _asInt(time['elapsed']);
      final team = raw['team'] as Map<String, dynamic>? ?? const {};
      final player = raw['player'] as Map<String, dynamic>? ?? const {};
      final playerName = player['name'] as String? ?? '';
      if (minute == null) continue;

      MatchEventType? eventType;
      if (type == 'Goal') {
        eventType = detail.toLowerCase().contains('penalty')
            ? MatchEventType.penaltyGoal
            : MatchEventType.goal;
      } else if (type == 'Card') {
        if (detail.toLowerCase().contains('yellow')) eventType = MatchEventType.yellowCard;
        if (detail.toLowerCase().contains('red')) eventType = MatchEventType.redCard;
      }
      if (eventType == null) continue; // ignore subs, VAR, etc.

      final isHome = (team['name'] as String? ?? '') == homeName;
      out.add(MatchEvent(
        minute: minute,
        type: eventType,
        player: playerName,
        side: isHome ? MatchSide.a : MatchSide.b,
      ));
    }
    out.sort((a, b) => a.minute.compareTo(b.minute));
    return out;
  }

  static List<GroupStanding> standingsFromJson(List<dynamic> response) {
    if (response.isEmpty) return const [];
    final first = response.first;
    if (first is! Map<String, dynamic>) return const [];
    final league = first['league'] as Map<String, dynamic>? ?? const {};
    final groups = league['standings'];
    if (groups is! List) return const [];

    final out = <GroupStanding>[];
    for (final group in groups) {
      if (group is! List || group.isEmpty) continue;
      final rows = <GroupStandingRow>[];
      String letter = '';
      for (var i = 0; i < group.length; i++) {
        final row = group[i];
        if (row is! Map<String, dynamic>) continue;
        final teamMap = row['team'] as Map<String, dynamic>? ?? const {};
        final all = row['all'] as Map<String, dynamic>? ?? const {};
        letter = _ptGroup(row['group'] as String? ?? letter);
        rows.add(GroupStandingRow(
          team: TeamLookup.resolve(teamMap['name'] as String? ?? '?'),
          points: _asInt(row['points']) ?? 0,
          played: _asInt(all['played']) ?? 0,
          wins: _asInt(all['win']) ?? 0,
          draws: _asInt(all['draw']) ?? 0,
          losses: _asInt(all['lose']) ?? 0,
          goalDiff: _asInt(row['goalsDiff']) ?? 0,
          qualified: i < 2,
        ));
      }
      if (rows.isNotEmpty) out.add(GroupStanding(letter: letter, rows: rows));
    }
    return out;
  }

  static List<Scorer> scorersFromJson(List<dynamic> response) {
    final out = <Scorer>[];
    for (var i = 0; i < response.length; i++) {
      final raw = response[i];
      if (raw is! Map<String, dynamic>) continue;
      final player = raw['player'] as Map<String, dynamic>? ?? const {};
      final stats = raw['statistics'];
      var goals = 0;
      if (stats is List && stats.isNotEmpty && stats.first is Map) {
        final g = (stats.first as Map)['goals'];
        if (g is Map) goals = _asInt(g['total']) ?? 0;
      }
      out.add(Scorer(
        rank: i + 1,
        player: player['name'] as String? ?? '?',
        team: TeamLookup.resolve(player['nationality'] as String? ?? '?'),
        goals: goals,
      ));
    }
    return out;
  }

  static List<HeadToHead> headToHeadFromJson(List<dynamic> response, {int limit = 5}) {
    final fixtures = <(DateTime, HeadToHead)>[];
    for (final raw in response) {
      if (raw is! Map<String, dynamic>) continue;
      final fixture = raw['fixture'] as Map<String, dynamic>? ?? const {};
      final league = raw['league'] as Map<String, dynamic>? ?? const {};
      final teams = raw['teams'] as Map<String, dynamic>? ?? const {};
      final goals = raw['goals'] as Map<String, dynamic>? ?? const {};
      final home = teams['home'] as Map<String, dynamic>? ?? const {};
      final away = teams['away'] as Map<String, dynamic>? ?? const {};
      final gh = _asInt(goals['home']);
      final ga = _asInt(goals['away']);
      if (gh == null || ga == null) continue;

      final flagH = TeamLookup.resolve(home['name'] as String? ?? '').flag;
      final flagA = TeamLookup.resolve(away['name'] as String? ?? '').flag;
      final date = DateTime.tryParse(fixture['date'] as String? ?? '') ?? DateTime(2000);
      fixtures.add((
        date,
        HeadToHead(
          fixture: '$flagH $gh – $ga $flagA',
          competition: league['name'] as String? ?? '',
          date: _fmtDate(date),
        ),
      ));
    }
    fixtures.sort((a, b) => b.$1.compareTo(a.$1)); // most recent first
    return [for (final f in fixtures.take(limit)) f.$2];
  }

  /// Splits an `/injuries?fixture=…` response into per-side team-news
  /// items. [homeName]/[awayName] decide which list each entry lands in.
  static (List<TeamNewsItem> home, List<TeamNewsItem> away) teamNewsFromInjuries(
    List<dynamic> response,
    String homeName,
    String awayName,
  ) {
    final home = <TeamNewsItem>[];
    final away = <TeamNewsItem>[];
    for (final raw in response) {
      if (raw is! Map<String, dynamic>) continue;
      final player = raw['player'] as Map<String, dynamic>? ?? const {};
      final team = raw['team'] as Map<String, dynamic>? ?? const {};
      final name = player['name'] as String? ?? '';
      final reason = player['reason'] as String? ?? player['type'] as String? ?? '';
      if (name.isEmpty) continue;

      final lower = reason.toLowerCase();
      final icon = lower.contains('red')
          ? '🟥'
          : lower.contains('yellow') || lower.contains('suspend')
              ? '🟨'
              : '➕';
      final item = TeamNewsItem(icon: icon, text: '$name — ${_ptReason(reason)}');

      final teamName = team['name'] as String? ?? '';
      if (teamName == homeName) {
        home.add(item);
      } else if (teamName == awayName) {
        away.add(item);
      }
    }
    return (home, away);
  }

  static String _fmtDate(DateTime d) {
    const months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final l = d.toLocal();
    return '${_two(l.day)} ${months[l.month - 1]} ${l.year}';
  }

  static String _ptGroup(String apiGroup) {
    // "Group A" -> "Grupo A"
    return apiGroup.replaceFirst(RegExp(r'^Group', caseSensitive: false), 'Grupo').trim();
  }

  static String _ptReason(String reason) {
    const map = {
      'suspended': 'Suspenso',
      'red card': 'Suspenso (cartão vermelho)',
      'yellow cards': 'Suspenso (cartões amarelos)',
      'injury': 'Lesão',
      'knock': 'Pancada',
      'illness': 'Doença',
      'questionable': 'Dúvida',
      'coach decision': 'Decisão técnica',
    };
    return map[reason.toLowerCase()] ?? reason;
  }

  /// Computes a team's group-stage result chips from the group-stage
  /// fixtures it appeared in. Group label / stat line are derived from
  /// standings by the repository and passed into [TeamGroupForm] there.
  static List<GroupFormGame> groupGames(
    String teamApiName,
    List<Map<String, dynamic>> groupFixtures,
  ) {
    final games = <GroupFormGame>[];
    for (final json in groupFixtures) {
      final teams = json['teams'] as Map<String, dynamic>? ?? const {};
      final goals = json['goals'] as Map<String, dynamic>? ?? const {};
      final home = teams['home'] as Map<String, dynamic>? ?? const {};
      final away = teams['away'] as Map<String, dynamic>? ?? const {};
      final homeName = home['name'] as String? ?? '';
      final awayName = away['name'] as String? ?? '';
      final gh = _asInt(goals['home']);
      final ga = _asInt(goals['away']);
      if (gh == null || ga == null) continue;

      final isHome = homeName == teamApiName;
      final isAway = awayName == teamApiName;
      if (!isHome && !isAway) continue;

      final own = isHome ? gh : ga;
      final opp = isHome ? ga : gh;
      final oppName = isHome ? awayName : homeName;
      final result = own > opp
          ? GameResult.win
          : own == opp
              ? GameResult.draw
              : GameResult.loss;
      games.add(GroupFormGame(
        result: result,
        score: '$own-$opp',
        opponent: TeamLookup.resolve(oppName),
      ));
    }
    return games;
  }

  static String ptGroup(String apiGroup) => _ptGroup(apiGroup);
}
