import '../../models/group_standing.dart';
import '../../models/match.dart';
import '../../models/match_detail.dart';
import '../../models/match_event.dart';
import '../../models/scorer.dart';
import '../../models/team.dart';
import '../api_football/team_lookup.dart';
import '../espn/espn_events_client.dart';
import '../espn/espn_events_mappers.dart';
import '../tournament_repository.dart';
import 'football_data_client.dart';
import 'football_data_config.dart';
import 'football_data_mappers.dart';

/// Live [TournamentRepository] backed by football-data.org v4 — the
/// app's free production feed. Same contract as the API-Football
/// implementation: [refresh] bulk-loads the shared snapshot (one
/// matches call + standings + scorers = 3 requests), match detail is
/// fetched lazily and cached.
///
/// Free-tier gaps, degraded gracefully: no goal/card timeline (events
/// stay empty → section hidden), no live minute, no venue, no injuries.
class FootballDataRepository implements TournamentRepository {
  FootballDataRepository({FootballDataClient? client, EspnEventsClient? espnClient})
      : _client = client ?? FootballDataClient(),
        _espn = espnClient ?? EspnEventsClient();

  final FootballDataClient _client;

  /// Supplemental, unofficial source for the goal/card timeline only —
  /// football-data's free tier has none. Best-effort: any failure just
  /// leaves the timeline empty.
  final EspnEventsClient _espn;

  /// Match id → ESPN event id, so a reopened match skips the
  /// scoreboard lookup.
  final Map<String, String> _espnEventIds = {};

  final Map<Round, List<Match>> _byRound = {
    Round.r32: [],
    Round.r16: [],
    Round.qf: [],
    Round.sf: [],
    Round.f: [],
  };
  final Map<String, Match> _byId = {};
  Match? _live;
  List<GroupStanding> _standings = const [];
  List<Scorer> _scorers = const [];

  /// football-data team name per side of each bracket match, for the
  /// group-form derivation in the detail sheet.
  final Map<String, ({String home, String away})> _apiNames = {};

  /// Finished group-stage matches, kept for computing campaigns.
  final List<Map<String, dynamic>> _groupMatches = [];

  /// Resolved team name → (group letter, rank, row) from standings.
  final Map<String, _GroupPos> _groupPosByTeam = {};

  final Map<String, MatchDetail> _detailCache = {};

  static const _wc = FootballDataConfig.competition;

  @override
  Future<void> refresh() async {
    final results = await Future.wait([
      _client.getJson('competitions/$_wc/matches'),
      _client.getJson('competitions/$_wc/standings'),
      _client.getJson('competitions/$_wc/scorers', query: {'limit': '20'}),
    ]);
    final qualified = _ingestMatches(results[0]);
    _standings = FootballDataMappers.standingsFromJson(
      results[1],
      qualifiedTeamNames: qualified,
    );
    _scorers = FootballDataMappers.scorersFromJson(results[2]);
    _indexStandings();
    _lastUpdatedAt = DateTime.now();
  }

  DateTime? _lastUpdatedAt;

  @override
  DateTime? get lastUpdatedAt => _lastUpdatedAt;

  /// Ingests the full fixture list; returns the resolved names of every
  /// team that reached the knockout phase (used to flag qualification
  /// in the group tables — the 2026 format advances 8 third-placed
  /// teams, so top-2 alone would under-mark).
  Set<String> _ingestMatches(Map<String, dynamic> json) {
    for (final list in _byRound.values) {
      list.clear();
    }
    _byId.clear();
    _apiNames.clear();
    _groupMatches.clear();
    _live = null;

    final qualified = <String>{};
    final matches = json['matches'];
    if (matches is! List) return qualified;

    for (final raw in matches) {
      if (raw is! Map<String, dynamic>) continue;
      final stage = raw['stage'] as String?;

      if (stage == 'GROUP_STAGE') {
        _groupMatches.add(raw);
        continue;
      }

      // Any knockout appearance (including the 3rd-place match, which
      // the bracket itself doesn't render) proves the team advanced
      // from its group.
      for (final side in ['homeTeam', 'awayTeam']) {
        final name = (raw[side] as Map<String, dynamic>?)?['name'] as String?;
        if (name != null) qualified.add(TeamLookup.resolve(name).name);
      }

      final round = FootballDataMappers.roundFromStage(stage);
      if (round == null) continue;

      final match = FootballDataMappers.matchFromJson(raw, round);
      _byRound[round]!.add(match);
      _byId[match.id] = match;
      _apiNames[match.id] = (
        home: (raw['homeTeam'] as Map<String, dynamic>?)?['name'] as String? ?? '',
        away: (raw['awayTeam'] as Map<String, dynamic>?)?['name'] as String? ?? '',
      );

      if (match.isLive && _live == null) _live = match;
    }

    final epoch = DateTime.utc(2026);
    for (final list in _byRound.values) {
      list.sort((a, b) => (a.kickoff ?? epoch).compareTo(b.kickoff ?? epoch));
    }
    _orderBracket();
    return qualified;
  }

  /// Reorders each knockout round into bracket order, so a match's two
  /// feeder games sit adjacent to it in the previous column and the
  /// connector lines pair the right cards. Linkage is derived from
  /// decided results: once a feeder finishes, its winner is named in
  /// the next round's fixture. Feeders still undecided keep their
  /// chronological position among the remaining slots and self-correct
  /// as results come in.
  void _orderBracket() {
    const pairs = [
      (Round.f, Round.sf),
      (Round.sf, Round.qf),
      (Round.qf, Round.r16),
      (Round.r16, Round.r32),
    ];
    for (final (next, prev) in pairs) {
      final nextMatches = _byRound[next]!;
      final pool = [..._byRound[prev]!];
      // Only reorder a fully-drawn pair of rounds — with a partial draw
      // there's no way to know which slots the missing fixtures occupy.
      if (nextMatches.isEmpty || pool.length != nextMatches.length * 2) {
        continue;
      }
      final slots = <Match?>[];
      for (final n in nextMatches) {
        slots.add(_takeFeeder(pool, n.teamA));
        slots.add(_takeFeeder(pool, n.teamB));
      }
      final ordered = [for (final m in slots) m ?? pool.removeAt(0)];
      _byRound[prev]!
        ..clear()
        ..addAll(ordered);
    }
  }

  /// Removes and returns the finished match in [pool] whose winner is
  /// [team], if any.
  Match? _takeFeeder(List<Match> pool, Team? team) {
    if (team == null) return null;
    for (var i = 0; i < pool.length; i++) {
      final m = pool[i];
      final side = m.winner;
      if (side == null) continue;
      final winner = side == MatchSide.a ? m.teamA : m.teamB;
      if (winner?.name == team.name) return pool.removeAt(i);
    }
    return null;
  }

  void _indexStandings() {
    _groupPosByTeam.clear();
    for (final group in _standings) {
      for (var i = 0; i < group.rows.length; i++) {
        _groupPosByTeam[group.rows[i].team.name] =
            _GroupPos(group.letter, i + 1, group.rows[i]);
      }
    }
  }

  @override
  List<Match> matchesByRound(Round round) => List.unmodifiable(_byRound[round]!);

  @override
  Match? matchById(String id) => _byId[id];

  @override
  Match? get liveMatch => _live;

  @override
  List<GroupStanding> get groupStandings => _standings;

  @override
  List<Scorer> get topScorers => _scorers;

  @override
  Future<MatchDetail> loadMatchDetail(Match match) async {
    final cached = _detailCache[match.id];
    if (cached != null) return cached;

    final teamA = match.teamA;
    final teamB = match.teamB;
    if (teamA == null || teamB == null) {
      return MatchDetail(events: match.events);
    }

    var fetchFailed = false;
    Map<String, dynamic> h2hJson = const {};
    try {
      h2hJson = await _client.getJson('matches/${match.id}/head2head', query: {'limit': '5'});
    } on FootballDataException {
      // Best-effort: group form below is derived from already-cached
      // data and still shows.
      fetchFailed = true;
    }

    final names = _apiNames[match.id];
    var events = match.events;
    if (match.isFinished || match.isLive) {
      try {
        events = await _espnEvents(match);
      } on Exception {
        fetchFailed = true; // retry on the next open
      }
    }

    final detail = MatchDetail(
      events: events,
      headToHead: FootballDataMappers.headToHeadFromJson(h2hJson),
      formA: _groupFormFor(teamA, names?.home ?? ''),
      formB: _groupFormFor(teamB, names?.away ?? ''),
    );
    // A live match's timeline keeps growing — never freeze it in cache.
    if (!fetchFailed && !match.isLive) _detailCache[match.id] = detail;
    return detail;
  }

  /// Pulls the goal/card timeline from ESPN by locating the same
  /// fixture on the kickoff day's scoreboard.
  Future<List<MatchEvent>> _espnEvents(Match match) async {
    final names = _apiNames[match.id];
    final kickoff = match.kickoff;
    if (names == null || kickoff == null) return match.events;

    var eventId = _espnEventIds[match.id];
    if (eventId == null) {
      final board = await _espn.scoreboard(kickoff);
      eventId = EspnEventsMappers.findEventId(board, home: names.home, away: names.away);
      if (eventId == null) return match.events;
      _espnEventIds[match.id] = eventId;
    }
    return EspnEventsMappers.eventsFromSummary(await _espn.summary(eventId));
  }

  TeamGroupForm _groupFormFor(Team team, String apiName) {
    final pos = _groupPosByTeam[team.name];
    final row = pos?.row;
    final statLine = row == null
        ? ''
        : '${row.played}J · ${row.wins}V ${row.draws}E ${row.losses}D · ${row.points} pts';
    final groupLabel = pos == null ? '' : '${pos.groupLetter} · ${pos.rank}º';
    return TeamGroupForm(
      team: team,
      groupLabel: groupLabel,
      statLine: statLine,
      games: FootballDataMappers.groupGames(apiName, _groupMatches),
    );
  }

  void dispose() {
    _client.dispose();
    _espn.dispose();
  }
}

class _GroupPos {
  final String groupLetter;
  final int rank;
  final GroupStandingRow row;
  _GroupPos(this.groupLetter, this.rank, this.row);
}
