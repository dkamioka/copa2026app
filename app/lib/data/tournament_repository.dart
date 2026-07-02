import '../models/group_standing.dart';
import '../models/match.dart';
import '../models/match_detail.dart';
import '../models/scorer.dart';

/// Data-access boundary for everything the app shows. Two
/// implementations exist: [MockTournamentRepository] (offline,
/// illustrative data) and the live API-backed one in
/// `data/api_football/`. The UI depends only on this interface.
///
/// The three tab views (bracket, groups, scorers) read from synchronous
/// getters that serve an in-memory snapshot; call [refresh] once at
/// startup (and whenever you want fresh data) to populate it. Per-match
/// detail — the goal timeline, head-to-head, and suspensions/injuries —
/// is loaded on demand via [loadMatchDetail], since each is a separate
/// network round-trip in the live source.
abstract class TournamentRepository {
  /// Bulk-loads fixtures, standings and scorers into the in-memory
  /// snapshot the sync getters serve. No-op for the mock.
  Future<void> refresh();

  /// When the snapshot was last (successfully) refreshed — shown in the
  /// header so users know how fresh the scores are. Null before the
  /// first load completes.
  DateTime? get lastUpdatedAt;

  List<Match> matchesByRound(Round round);

  Match? matchById(String id);

  /// The single in-progress match to feature in the live banner, if any.
  Match? get liveMatch;

  List<GroupStanding> get groupStandings;

  List<Scorer> get topScorers;

  /// Loads (and caches) the detail bundle for a single match.
  Future<MatchDetail> loadMatchDetail(Match match);
}
