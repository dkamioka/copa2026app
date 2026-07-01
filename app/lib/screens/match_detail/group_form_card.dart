import 'package:flutter/cupertino.dart';

import '../../models/group_standing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/team_chip.dart';

class GroupFormCard extends StatelessWidget {
  const GroupFormCard({super.key, required this.form});

  final TeamGroupForm form;

  Color _resultColor(GameResult r) => switch (r) {
        GameResult.win => AppColors.win,
        GameResult.draw => AppColors.draw,
        GameResult.loss => AppColors.loss,
      };

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TeamColorChip(team: form.team, size: 13),
              const SizedBox(width: 8),
              TeamFlag(flag: form.team.flag, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  form.team.name,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              Text(form.groupLabel, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.inkFaint)),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            form.statLine,
            style: const TextStyle(fontSize: 11, color: AppColors.inkFainter, fontFeatures: [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final g in form.games)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0x0D16162E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: _resultColor(g.result)),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${g.score} ${g.opponent.code}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xCC16162E),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
