import 'package:flutter/cupertino.dart';

import '../../data/tournament_repository.dart';
import '../../theme/app_theme.dart';
import 'group_card.dart';

class GroupsView extends StatelessWidget {
  const GroupsView({super.key, required this.repository});

  final TournamentRepository repository;

  @override
  Widget build(BuildContext context) {
    final groups = repository.groupStandings;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 40),
      itemCount: groups.length + 1,
      separatorBuilder: (context, i) => const SizedBox(height: 11),
      itemBuilder: (context, i) {
        if (i == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text('Fase de Grupos', style: AppTextStyles.sectionHeader),
          );
        }
        return GroupCard(group: groups[i - 1]);
      },
    );
  }
}
