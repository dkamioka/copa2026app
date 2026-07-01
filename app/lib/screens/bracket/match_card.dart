import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../models/match.dart';
import '../../models/match_event.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/team_chip.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({super.key, required this.match, required this.onTap});

  final Match match;
  final VoidCallback onTap;

  Color get _footerColor {
    if (match.isFinished) return AppColors.inkFainter;
    if (match.isLive) return AppColors.accent;
    return AppColors.inkFaint;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SoftCard(
        borderRadius: BorderRadius.circular(AppRadii.card),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              match.footerLabel.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: _footerColor,
              ),
            ),
            const SizedBox(height: 6),
            _TeamLine(
              team: match.teamA,
              flag: match.flagA,
              name: match.nameA,
              score: match.scoreLabelA,
              muted: match.isFinished && match.winner == MatchSide.b,
              emphasize: match.isFinished && match.winner == MatchSide.a,
            ),
            const SizedBox(height: 5),
            _TeamLine(
              team: match.teamB,
              flag: match.flagB,
              name: match.nameB,
              score: match.scoreLabelB,
              muted: match.isFinished && match.winner == MatchSide.a,
              emphasize: match.isFinished && match.winner == MatchSide.b,
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({
    required this.team,
    required this.flag,
    required this.name,
    required this.score,
    required this.muted,
    required this.emphasize,
  });

  final Team? team;
  final String flag;
  final String name;
  final String score;
  final bool muted;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final color = muted ? AppColors.inkFaint : AppColors.ink;
    return Row(
      children: [
        TeamColorChip(team: team, size: 9),
        const SizedBox(width: 6),
        TeamFlag(flag: flag, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
              color: color,
            ),
          ),
        ),
        if (score.isNotEmpty)
          Text(
            score,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
      ],
    );
  }
}
