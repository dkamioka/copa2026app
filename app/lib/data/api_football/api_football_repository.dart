import '../../models/group_standing.dart';
import '../../models/match.dart';
import '../../models/match_detail.dart';
import '../../models/scorer.dart';
import '../../models/team.dart';
import '../tournament_repository.dart';
import 'api_config.dart';
import 'api_football_client.dart';
import 'api_football_mappers.dart';

/// Live [TournamentRepository] backed by API-Football v3.
///
/// [refresh] bulk-loads the cheap, shared data (all fixtures, standings,
/// scorers) into an in-memory snapshot that the synchronous tab getters
/// serve. Per-match detail (goal timeline, head-to-head, injuries) is
/// fetched lazily by [loadMatchDetail] and cached, so opening a match
/// costs at most a few requests once.
class ApiFootballRepository implements TournamentRepository {
  ApiFootballRepository({ApiFootballClient? client})
      : _client = client ?? ApiFootballClient();

  final ApiFootballClient _client;

  final Map<Round, List<Match>> _byRound = {
    Round.r16: [],
    Round.qf: [],
    Round.sf: [],
    Round.f: [],
  };
  final Map<String, Match> _byId = {};
  Match? _live;
  List<GroupStanding> _standings = const [];
  List<Scorer> _scorers = const [];

  /// Extra API context per knockout match, needed for detail fetches
  /// (head-to-head needs the two teams' English names for flags; the
  /// fixture id is the match id).
  final Map<String, _MatchRef> _refs = {};

  /// Group-stage fixtures kept for computing each team's campaign.
  final List<Map<String, dynamic>> _groupFixtures = [];

  /// English team name → (group letter, rank) from standings.
  final Map<String, _GroupPos> _groupPosByTeam = {};

  final Map<String, MatchDetail> _detailCache = {};

  static Map<String, String> get _leagueQuery => {
        'league': '${ApiConfig.worldCupLeagueId}',
        'season': '${ApiConfig.season}',
      };

  @override
  Future<void> refresh() async {
    final results = await Future.wait([
      _client.getAll('fixtures', _leagueQuery),
      _client.getAll('standings', _leagueQuery),
      _client.getAll('players/topscorers', _leagueQuery),
    ]);
    _ingestFixtures(results[0]);
    _standings = ApiFootballMappers.standingsFromJson(results[1]);
    _scorers = ApiFootballMappers.scorersFromJson(results[2]);
    _indexStandings();
  }

  void _ingestFixtures(List<dynamic> fixtures) {
    for (final list in _byRound.values) {
      list.clear();
    }
    _byId.clear();
    _refs.clear();
    _groupFixtures.clear();
    _live = null;

    for (final raw in fixtures) {
      if (raw is! Map<String, dynamic>) continue;
      final league = raw['league'] as Map<String, dynamic>? ?? const {};
      final roundLabel = league['round'] as String? ?? '';
      final round = ApiFootballMappers.roundFromLabel(roundLabel);

      if (round == null) {
        if (roundLabel.toLowerCase().contains('group')) _groupFixtures.add(raw);
        continue;
      }

      final match = ApiFootballMappers.matchFromFixture(raw, round);
      _byRound[round]!.add(match);
      _byId[match.id] = match;

      final teams = raw['teams'] as Map<String, dynamic>? ?? const {};
      final home = teams['home'] as Map<String, dynamic>? ?? const {};
      final away = teams['away'] as Map<String, dynamic>? ?? const {};
      _refs[match.id] = _MatchRef(
        fixtureId: match.id,
        homeId: (home['id'] as num?)?.toInt(),
        awayId: (away['id'] as num?)?.toInt(),
        homeName: home['name'] as String? ?? '',
        awayName: away['name'] as String? ?? '',
      );

      if (match.isLive && _live == null) _live = match;
    }

    // Order each round's matches by kickoff so the bracket reads
    // top-to-bottom in a stable, chronological order.
    for (final list in _byRound.values) {
      list.sort((a, b) => a.dateLong.compareTo(b.dateLong));
    }
  }

  void _indexStandings() {
    _groupPosByTeam.clear();
    for (final group in _standings) {
      for (var i = 0; i < group.rows.length; i++) {
        _groupPosByTeam[group.rows[i].team.name] = _GroupPos(group.letter, i + 1, group.rows[i]);
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

    final ref = _refs[match.id];
    final teamA = match.teamA;
    final teamB = match.teamB;
    if (ref == null || teamA == null || teamB == null) {
      return MatchDetail(events: match.events);
    }

    final futures = <Future<List<dynamic>>>[
      _client.getAll('fixtures/events', {'fixture': ref.fixtureId}),
      _client.getAll('injuries', {'fixture': ref.fixtureId}),
      if (ref.homeId != null && ref.awayId != null)
        _client.getAll('fixtures/headtohead', {'h2h': '${ref.homeId}-${ref.awayId}'})
      else
        Future.value(const []),
    ];

    List<List<dynamic>> results;
    try {
      results = await Future.wait(futures);
    } on ApiFootballException {
      // Detail is best-effort — if a per-match call fails (quota, etc.)
      // still show whatever we can (group form is already cached).
      results = [const [], const [], const []];
    }

    final events = ApiFootballMappers.eventsFromJson(results[0], ref.homeName);
    final (newsA, newsB) =
        ApiFootballMappers.teamNewsFromInjuries(results[1], ref.homeName, ref.awayName);
    final h2h = ApiFootballMappers.headToHeadFromJson(results[2]);

    final detail = MatchDetail(
      events: events,
      headToHead: h2h,
      formA: _groupFormFor(teamA, ref.homeName),
      formB: _groupFormFor(teamB, ref.awayName),
      newsA: newsA,
      newsB: newsB,
    );
    _detailCache[match.id] = detail;
    return detail;
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
      games: ApiFootballMappers.groupGames(apiName, _groupFixtures),
    );
  }

  void dispose() => _client.dispose();
}

class _MatchRef {
  final String fixtureId;
  final int? homeId;
  final int? awayId;
  final String homeName;
  final String awayName;
  _MatchRef({
    required this.fixtureId,
    required this.homeId,
    required this.awayId,
    required this.homeName,
    required this.awayName,
  });
}

class _GroupPos {
  final String groupLetter;
  final int rank;
  final GroupStandingRow row;
  _GroupPos(this.groupLetter, this.rank, this.row);
}
