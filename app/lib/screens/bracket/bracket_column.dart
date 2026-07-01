import 'package:flutter/cupertino.dart';

import '../../models/match.dart';
import '../../theme/app_theme.dart';
import 'match_card.dart';

const double kBracketColumnHeight = 620;
const double kBracketColumnWidth = 176;
const double kBracketConnectorWidth = 18;

class BracketColumn extends StatelessWidget {
  const BracketColumn({
    super.key,
    required this.label,
    required this.matches,
    required this.onOpen,
    this.highlightId,
  });

  final String label;
  final List<Match> matches;
  final ValueChanged<Match> onOpen;
  final String? highlightId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kBracketColumnWidth,
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: AppColors.inkFainter,
                ),
              ),
            ),
          ),
          SizedBox(
            height: kBracketColumnHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final m in matches)
                    MatchCard(match: m, onTap: () => onOpen(m)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
