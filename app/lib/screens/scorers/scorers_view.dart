import 'package:flutter/cupertino.dart';

import '../../data/tournament_repository.dart';
import '../../models/scorer.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/team_chip.dart';

class ScorersView extends StatelessWidget {
  const ScorersView({super.key, required this.repository});

  final TournamentRepository repository;

  @override
  Widget build(BuildContext context) {
    final scorers = repository.topScorers;
    if (scorers.isEmpty) {
      return ListView(
        key: const PageStorageKey('scorers_list'),
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 40),
        children: const [
          Text('Artilheiros', style: AppTextStyles.sectionHeader),
          SizedBox(height: 10),
          EmptyStateCard(
            emoji: '⚽',
            title: 'Ainda sem gols',
            message: 'O ranking de artilheiros aparece aqui depois dos '
                'primeiros gols do torneio.',
          ),
        ],
      );
    }
    return ListView(
      // Keeps the scroll offset across tab switches (the AnimatedSwitcher
      // in HomeShell rebuilds each tab from scratch).
      key: const PageStorageKey('scorers_list'),
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 40),
      children: [
        const Text('Artilheiros', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 11),
        SoftCard(
          borderRadius: BorderRadius.circular(AppRadii.cardLarge),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              for (var i = 0; i < scorers.length; i++)
                _ScorerRow(scorer: scorers[i], showDivider: i != scorers.length - 1),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScorerRow extends StatelessWidget {
  const _ScorerRow({required this.scorer, required this.showDivider});

  final Scorer scorer;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final rankColor = scorer.rank == 1 ? AppColors.accent : AppColors.inkFaint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0x0F16162E)))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              '${scorer.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: rankColor, fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
          const SizedBox(width: 11),
          TeamColorChip(team: scorer.team, size: 11),
          const SizedBox(width: 11),
          TeamFlag(flag: scorer.team.flag, size: 16),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scorer.player,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                Text(scorer.team.name, style: const TextStyle(fontSize: 10.5, color: AppColors.inkFaint)),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${scorer.goals}',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink, fontFeatures: [FontFeature.tabularFigures()]),
              ),
              const SizedBox(width: 4),
              const Text('gols', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.inkFainter)),
            ],
          ),
        ],
      ),
    );
  }
}
