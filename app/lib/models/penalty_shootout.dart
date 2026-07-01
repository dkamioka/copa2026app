import 'match_event.dart';

/// A single penalty-kick result: true = scored, false = missed.
typedef PenaltyKick = bool;

class PenaltyShootout {
  final List<PenaltyKick> teamA;
  final List<PenaltyKick> teamB;
  final MatchSide winner;

  const PenaltyShootout({
    required this.teamA,
    required this.teamB,
    required this.winner,
  });

  int get scoreA => teamA.where((k) => k).length;
  int get scoreB => teamB.where((k) => k).length;
  String get scoreLine => '$scoreA  –  $scoreB';
}
