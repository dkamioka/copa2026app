enum MatchEventType { goal, penaltyGoal, yellowCard, redCard }

enum MatchSide { a, b }

class MatchEvent {
  final int minute;
  final MatchEventType type;
  final String player;
  final MatchSide side;

  const MatchEvent({
    required this.minute,
    required this.type,
    required this.player,
    required this.side,
  });

  String get icon {
    switch (type) {
      case MatchEventType.goal:
      case MatchEventType.penaltyGoal:
        return '⚽';
      case MatchEventType.yellowCard:
        return '🟨';
      case MatchEventType.redCard:
        return '🟥';
    }
  }

  String get label => type == MatchEventType.penaltyGoal ? '$player (pên)' : player;
}
