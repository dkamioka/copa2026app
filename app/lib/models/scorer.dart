import 'team.dart';

class Scorer {
  final int rank;
  final String player;
  final Team team;
  final int goals;

  const Scorer({
    required this.rank,
    required this.player,
    required this.team,
    required this.goals,
  });
}
