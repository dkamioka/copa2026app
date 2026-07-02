import 'package:flutter/cupertino.dart';

import '../../data/tournament_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_card.dart';
import 'group_card.dart';

class GroupsView extends StatelessWidget {
  const GroupsView({super.key, required this.repository});

  final TournamentRepository repository;

  @override
  Widget build(BuildContext context) {
    final groups = repository.groupStandings;
    if (groups.isEmpty) {
      return ListView(
        key: const PageStorageKey('groups_list'),
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 40),
        children: const [
          Text('Fase de Grupos', style: AppTextStyles.sectionHeader),
          SizedBox(height: 10),
          EmptyStateCard(
            emoji: '📊',
            title: 'Classificação em breve',
            message: 'A tabela dos grupos aparece aqui assim que a fonte '
                'de dados publicar as primeiras rodadas.',
          ),
        ],
      );
    }
    return ListView.separated(
      // Keeps the scroll offset across tab switches (the AnimatedSwitcher
      // in HomeShell rebuilds each tab from scratch).
      key: const PageStorageKey('groups_list'),
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
