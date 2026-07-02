import '../../models/match_event.dart';
import '../api_football/team_lookup.dart';

/// Pure JSON → domain mapping for the unofficial ESPN feed (see
/// EspnEventsClient). Shapes verified against the live 2026 World Cup
/// feed — see test/espn_events_mappers_test.dart for real samples.
abstract final class EspnEventsMappers {
  /// Finds, on a scoreboard day, the ESPN event whose home/away teams
  /// resolve to the same canonical teams as [home]/[away] (both are
  /// football-data English names; ESPN uses near-identical naming, and
  /// [TeamLookup] absorbs the variants). Null when not found.
  static String? findEventId(
    Map<String, dynamic> scoreboard, {
    required String home,
    required String away,
  }) {
    final targetHome = TeamLookup.resolve(home).name;
    final targetAway = TeamLookup.resolve(away).name;
    final events = scoreboard['events'];
    if (events is! List) return null;

    for (final event in events) {
      if (event is! Map<String, dynamic>) continue;
      final competitions = event['competitions'];
      if (competitions is! List || competitions.isEmpty) continue;
      final competitors = (competitions.first as Map<String, dynamic>)['competitors'];
      if (competitors is! List) continue;

      String? homeName;
      String? awayName;
      for (final c in competitors) {
        if (c is! Map<String, dynamic>) continue;
        final name = (c['team'] as Map<String, dynamic>?)?['displayName'] as String?;
        if (c['homeAway'] == 'home') homeName = name;
        if (c['homeAway'] == 'away') awayName = name;
      }
      if (homeName == null || awayName == null) continue;
      if (TeamLookup.resolve(homeName).name == targetHome &&
          TeamLookup.resolve(awayName).name == targetAway) {
        return event['id'] as String?;
      }
    }
    return null;
  }

  /// Maps a summary's `keyEvents` to the goal/card timeline. Skips
  /// everything that isn't a goal or a card (kickoff, subs, delays)
  /// and the penalty shootout (shown separately from [Match.penalties]).
  static List<MatchEvent> eventsFromSummary(Map<String, dynamic> summary) {
    final homeName = _headerHomeName(summary);
    if (homeName == null) return const [];
    final resolvedHome = TeamLookup.resolve(homeName).name;

    final keyEvents = summary['keyEvents'];
    if (keyEvents is! List) return const [];

    final out = <MatchEvent>[];
    for (final raw in keyEvents) {
      if (raw is! Map<String, dynamic>) continue;
      if (raw['shootout'] == true) continue;

      final typeText = ((raw['type'] as Map<String, dynamic>?)?['text'] as String? ?? '').toLowerCase();
      final isScore = raw['scoringPlay'] == true;

      MatchEventType? type;
      if (isScore) {
        type = typeText.contains('penalty') ? MatchEventType.penaltyGoal : MatchEventType.goal;
      } else if (typeText.contains('yellow')) {
        type = MatchEventType.yellowCard;
      } else if (typeText.contains('red')) {
        type = MatchEventType.redCard;
      }
      if (type == null) continue;

      final teamName = (raw['team'] as Map<String, dynamic>?)?['displayName'] as String?;
      if (teamName == null) continue;
      final side = TeamLookup.resolve(teamName).name == resolvedHome ? MatchSide.a : MatchSide.b;

      var player = '';
      final participants = raw['participants'];
      if (participants is List && participants.isNotEmpty) {
        final first = participants.first;
        if (first is Map<String, dynamic>) {
          final athlete = first['athlete'] as Map<String, dynamic>?;
          player = athlete?['displayName'] as String? ?? '';
        }
      }
      if (typeText.contains('own')) player = '$player (contra)';

      out.add(MatchEvent(
        minute: _minuteFrom(raw),
        type: type,
        player: player,
        side: side,
      ));
    }
    return out;
  }

  static String? _headerHomeName(Map<String, dynamic> summary) {
    final competitions = (summary['header'] as Map<String, dynamic>?)?['competitions'];
    if (competitions is! List || competitions.isEmpty) return null;
    final competitors = (competitions.first as Map<String, dynamic>)['competitors'];
    if (competitors is! List) return null;
    for (final c in competitors) {
      if (c is Map<String, dynamic> && c['homeAway'] == 'home') {
        return (c['team'] as Map<String, dynamic>?)?['displayName'] as String?;
      }
    }
    return null;
  }

  /// "29'" / "45'+4'" → 29 / 45.
  static int _minuteFrom(Map<String, dynamic> raw) {
    final display = (raw['clock'] as Map<String, dynamic>?)?['displayValue'] as String? ?? '';
    final m = RegExp(r'^(\d+)').firstMatch(display);
    return m != null ? int.parse(m.group(1)!) : 0;
  }
}
