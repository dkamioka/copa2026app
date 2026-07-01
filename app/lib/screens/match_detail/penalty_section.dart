import 'package:flutter/cupertino.dart';

import '../../models/match.dart';
import '../../models/match_event.dart';
import '../../theme/app_theme.dart';
import '../../widgets/surfaces.dart';

class PenaltySection extends StatelessWidget {
  const PenaltySection({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final pens = match.penalties!;
    final winnerName = pens.winner == MatchSide.a ? match.nameA : match.nameB;
    return SoftCard(
      borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Column(
        children: [
          const Text(
            'DISPUTA DE PÊNALTIS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pens.scoreLine,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              fontFeatures: [FontFeature.tabularFigures()],
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          _KickRow(flag: match.flagA, kicks: pens.teamA),
          const SizedBox(height: 9),
          _KickRow(flag: match.flagB, kicks: pens.teamB),
          const SizedBox(height: 12),
          Text(
            '$winnerName avança de fase',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xB316162E)),
          ),
        ],
      ),
    );
  }
}

class _KickRow extends StatelessWidget {
  const _KickRow({required this.flag, required this.kicks});

  final String flag;
  final List<bool> kicks;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 26, child: Center(child: Text(flag, style: const TextStyle(fontSize: 19)))),
        const SizedBox(width: 10),
        Row(
          children: [
            for (final k in kicks)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: k ? AppColors.win : AppColors.loss,
                  ),
                  child: Center(
                    child: Text(
                      k ? '✓' : '✗',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: CupertinoColors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
