import 'team.dart';

class GroupStandingRow {
  final Team team;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalDiff;
  final bool qualified;

  const GroupStandingRow({
    required this.team,
    required this.points,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalDiff,
    required this.qualified,
  });

  String get goalDiffLabel => goalDiff > 0 ? '+$goalDiff' : '$goalDiff';
}

class GroupStanding {
  final String letter;
  final List<GroupStandingRow> rows;

  const GroupStanding({required this.letter, required this.rows});
}

enum GameResult { win, draw, loss }

class GroupFormGame {
  final GameResult result;
  final String score;
  final Team opponent;

  const GroupFormGame({
    required this.result,
    required this.score,
    required this.opponent,
  });
}

/// A team's group-stage campaign summary, shown in the match detail sheet.
class TeamGroupForm {
  final Team team;
  final String groupLabel;
  final String statLine;
  final List<GroupFormGame> games;

  const TeamGroupForm({
    required this.team,
    required this.groupLabel,
    required this.statLine,
    required this.games,
  });
}
