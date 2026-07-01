import 'package:flutter/cupertino.dart';

import '../../models/head_to_head.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/team_chip.dart';

class TeamNewsCard extends StatelessWidget {
  const TeamNewsCard({super.key, required this.team, required this.items});

  final Team team;
  final List<TeamNewsItem> items;

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
              TeamColorChip(team: team, size: 12),
              const SizedBox(width: 8),
              TeamFlag(flag: team.flag, size: 15),
              const SizedBox(width: 8),
              Text(team.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 8),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(it.icon, style: const TextStyle(fontSize: 13, height: 1.3)),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      it.text,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xD216162E), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
