import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../data/tournament_repository.dart';
import '../../models/match.dart';
import '../../theme/app_theme.dart';
import '../match_detail/match_detail_sheet.dart';
import 'bracket_column.dart';
import 'bracket_connector.dart';
import 'live_match_banner.dart';

class BracketView extends StatefulWidget {
  const BracketView({super.key, required this.repository});

  final TournamentRepository repository;

  @override
  State<BracketView> createState() => _BracketViewState();
}

class _BracketViewState extends State<BracketView> {
  final _hController = ScrollController();

  static const _rounds = [Round.r16, Round.qf, Round.sf, Round.f];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(Round.qf, animate: false));
  }

  @override
  void dispose() {
    _hController.dispose();
    super.dispose();
  }

  double _offsetFor(Round round) {
    // R16 | conn | QF | conn | SF | conn | F
    const col = kBracketColumnWidth;
    const conn = kBracketConnectorWidth;
    switch (round) {
      case Round.r16:
        return 0;
      case Round.qf:
        return col + conn;
      case Round.sf:
        return (col + conn) * 2;
      case Round.f:
        return (col + conn) * 3;
    }
  }

  void _scrollTo(Round round, {bool animate = true}) {
    if (!_hController.hasClients) return;
    final target = (_offsetFor(round) - 18).clamp(0.0, _hController.position.maxScrollExtent);
    if (animate) {
      _hController.animateTo(target, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    } else {
      _hController.jumpTo(target);
    }
  }

  void _openMatch(Match m) {
    showMatchDetailSheet(context, widget.repository, m);
  }

  @override
  Widget build(BuildContext context) {
    final repo = widget.repository;
    final live = repo.liveMatch;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 40),
      children: [
        if (live != null) ...[
          LiveMatchBanner(match: live, onTap: () => _openMatch(live)),
          const SizedBox(height: 13),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Chave', style: AppTextStyles.sectionHeader),
            Row(
              children: [
                for (final r in _rounds) _RoundJumpChip(round: r, onTap: () => _scrollTo(r)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          controller: _hController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BracketColumn(
                label: Round.r16.shortLabel,
                matches: repo.matchesByRound(Round.r16),
                onOpen: _openMatch,
              ),
              const BracketConnector(sourceMatchCount: 8),
              BracketColumn(
                label: Round.qf.shortLabel,
                matches: repo.matchesByRound(Round.qf),
                onOpen: _openMatch,
              ),
              const BracketConnector(sourceMatchCount: 4),
              BracketColumn(
                label: Round.sf.shortLabel,
                matches: repo.matchesByRound(Round.sf),
                onOpen: _openMatch,
              ),
              const BracketConnector(sourceMatchCount: 2),
              BracketColumn(
                label: Round.f.shortLabel,
                matches: repo.matchesByRound(Round.f),
                onOpen: _openMatch,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Toque em um jogo para ver lances, campanha e desfalques',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption,
          ),
        ),
      ],
    );
  }
}

class _RoundJumpChip extends StatelessWidget {
  const _RoundJumpChip({required this.round, required this.onTap});

  final Round round;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x0F16162E),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            round.shortLabel,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkFainter,
            ),
          ),
        ),
      ),
    );
  }
}
