import 'package:flutter/cupertino.dart';

import '../../models/group_standing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/team_chip.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group});

  final GroupStanding group;

  static const _colFlex = [2, 8, 3, 2, 2, 2, 2, 3];

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.letter, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 8),
          _HeaderRow(),
          for (var i = 0; i < group.rows.length; i++) _StandingRow(row: group.rows[i], position: i + 1),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: AppColors.qualifiedBg, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 6),
              const Text('Classificados para a fase final', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: AppColors.inkHint);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        children: [
          Expanded(flex: GroupCard._colFlex[0], child: const SizedBox.shrink()),
          Expanded(flex: GroupCard._colFlex[1], child: const Text('EQUIPE', style: style)),
          Expanded(flex: GroupCard._colFlex[2], child: const Text('PTS', textAlign: TextAlign.center, style: style)),
          Expanded(flex: GroupCard._colFlex[3], child: const Text('J', textAlign: TextAlign.center, style: style)),
          Expanded(flex: GroupCard._colFlex[4], child: const Text('V', textAlign: TextAlign.center, style: style)),
          Expanded(flex: GroupCard._colFlex[5], child: const Text('E', textAlign: TextAlign.center, style: style)),
          Expanded(flex: GroupCard._colFlex[6], child: const Text('D', textAlign: TextAlign.center, style: style)),
          Expanded(flex: GroupCard._colFlex[7], child: const Text('SG', textAlign: TextAlign.center, style: style)),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.row, required this.position});

  final GroupStandingRow row;
  final int position;

  @override
  Widget build(BuildContext context) {
    final posColor = row.qualified ? AppColors.qualifiedText : AppColors.inkHint;
    final weight = row.qualified ? FontWeight.w700 : FontWeight.w500;
    final numStyle = const TextStyle(fontSize: 11.5, color: Color(0x9916162E), fontFeatures: [FontFeature.tabularFigures()]);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      decoration: BoxDecoration(
        color: row.qualified ? AppColors.qualifiedBg : const Color(0x00000000),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: GroupCard._colFlex[0],
            child: Text('$position',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: posColor)),
          ),
          Expanded(
            flex: GroupCard._colFlex[1],
            child: Row(
              children: [
                TeamColorChip(team: row.team, size: 9),
                const SizedBox(width: 6),
                TeamFlag(flag: row.team.flag, size: 12),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    row.team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, fontWeight: weight, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: GroupCard._colFlex[2],
            child: Text('${row.points}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ink, fontFeatures: [FontFeature.tabularFigures()])),
          ),
          Expanded(flex: GroupCard._colFlex[3], child: Text('${row.played}', textAlign: TextAlign.center, style: numStyle)),
          Expanded(flex: GroupCard._colFlex[4], child: Text('${row.wins}', textAlign: TextAlign.center, style: numStyle)),
          Expanded(flex: GroupCard._colFlex[5], child: Text('${row.draws}', textAlign: TextAlign.center, style: numStyle)),
          Expanded(flex: GroupCard._colFlex[6], child: Text('${row.losses}', textAlign: TextAlign.center, style: numStyle)),
          Expanded(flex: GroupCard._colFlex[7], child: Text(row.goalDiffLabel, textAlign: TextAlign.center, style: numStyle)),
        ],
      ),
    );
  }
}
