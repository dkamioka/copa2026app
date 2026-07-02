import 'package:flutter/cupertino.dart';

import '../../models/match.dart';
import '../../models/team.dart';
import '../../theme/app_theme.dart';

class ScoreHeader extends StatelessWidget {
  const ScoreHeader({super.key, required this.match});

  final Match match;

  Color get _statusColor {
    if (match.isLive) return AppColors.accent;
    if (match.isFinished) return AppColors.inkFainter;
    return AppColors.ink;
  }

  Color get _statusBg {
    if (match.isLive) return AppColors.accent.withValues(alpha: 0.12);
    return const Color(0x1216162E);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          match.round.fullLabel.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          // Venue is unavailable on some data sources — show only what
          // exists instead of a dangling separator.
          [match.venue, match.dateLong].where((s) => s.isNotEmpty).join('   ·   '),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.inkFainter),
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _TeamColumn(flag: match.flagA, name: match.nameA, team: match.teamA)),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    Text(
                      match.heroScore,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        match.statusLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: _statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _TeamColumn(flag: match.flagB, name: match.nameB, team: match.teamB)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.flag, required this.name, required this.team});

  final String flag;
  final String name;
  final Team? team;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(flag, style: const TextStyle(fontSize: 42, height: 1)),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Container(
          width: 28,
          height: 4,
          decoration: BoxDecoration(
            gradient: team?.chipGradient,
            color: team == null ? const Color(0x2616162E) : null,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
