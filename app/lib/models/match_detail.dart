import 'group_standing.dart';
import 'head_to_head.dart';
import 'match_event.dart';

/// Everything the match-detail sheet shows below the score header, loaded
/// as one bundle. For the mock this is built instantly from in-memory
/// data; for the live API it's fetched on demand (goal timeline, H2H,
/// and suspensions/injuries are each a separate endpoint), which is why
/// the repository exposes it behind a `Future`.
class MatchDetail {
  final List<MatchEvent> events;
  final List<HeadToHead> headToHead;
  final TeamGroupForm? formA;
  final TeamGroupForm? formB;
  final List<TeamNewsItem> newsA;
  final List<TeamNewsItem> newsB;

  const MatchDetail({
    this.events = const [],
    this.headToHead = const [],
    this.formA,
    this.formB,
    this.newsA = const [],
    this.newsB = const [],
  });

  static const empty = MatchDetail();
}
