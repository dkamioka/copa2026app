import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../data/tournament_repository.dart';
import '../../models/match.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_card.dart';
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

  /// Rounds that actually have fixtures in the current data source —
  /// the 2026 Round of 32 shows up on the live feed, while the mock
  /// (and any pre-draw state) simply omits its column.
  List<Round> get _visibleRounds => [
        for (final r in Round.values)
          if (widget.repository.matchesByRound(r).isNotEmpty) r,
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final round = _initialRound();
      if (round != null) _scrollTo(round, animate: false);
    });
  }

  /// The round worth landing on: the live match's round, else the
  /// earliest round with a match still to play, else the latest drawn.
  Round? _initialRound() {
    final rounds = _visibleRounds;
    if (rounds.isEmpty) return null;
    final live = widget.repository.liveMatch;
    if (live != null && rounds.contains(live.round)) return live.round;
    for (final r in rounds) {
      if (widget.repository.matchesByRound(r).any((m) => !m.isFinished)) return r;
    }
    return rounds.last;
  }

  @override
  void dispose() {
    _hController.dispose();
    super.dispose();
  }

  double _offsetFor(Round round) {
    final index = _visibleRounds.indexOf(round);
    if (index <= 0) return 0;
    return (kBracketColumnWidth + kBracketConnectorWidth) * index;
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
    final rounds = _visibleRounds;

    if (rounds.isEmpty) {
      // Honest pre-knockout state: before the bracket is drawn the live
      // feed legitimately has no knockout fixtures — say so instead of
      // rendering four empty columns.
      return ListView(
        key: const PageStorageKey('bracket_list'),
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 40),
        children: const [
          Text('Chave', style: AppTextStyles.sectionHeader),
          SizedBox(height: 10),
          EmptyStateCard(
            emoji: '🗓️',
            title: 'Chave em definição',
            message: 'Os confrontos do mata-mata aparecem aqui assim que os '
                'classificados forem definidos. Acompanhe a fase de grupos '
                'na aba Classificação.',
          ),
        ],
      );
    }

    return ListView(
      // Keeps the scroll offset across tab switches (the AnimatedSwitcher
      // in HomeShell rebuilds each tab from scratch).
      key: const PageStorageKey('bracket_list'),
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
                for (final r in rounds) _RoundJumpChip(round: r, onTap: () => _scrollTo(r)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          controller: _hController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Builder(builder: (context) {
            // Every column shares one height, scaled so the densest
            // round keeps the same per-match density the original
            // 8-match layout had (the 2026 R32 holds 16 matches).
            final maxMatches = rounds
                .map((r) => repo.matchesByRound(r).length)
                .reduce((a, b) => a > b ? a : b);
            final height = maxMatches <= 8
                ? kBracketColumnHeight
                : kBracketColumnHeight * maxMatches / 8;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < rounds.length; i++) ...[
                  if (i > 0)
                    BracketConnector(
                      sourceMatchCount: repo.matchesByRound(rounds[i - 1]).length,
                      height: height,
                    ),
                  BracketColumn(
                    label: rounds[i].shortLabel,
                    matches: repo.matchesByRound(rounds[i]),
                    onOpen: _openMatch,
                    height: height,
                  ),
                ],
              ],
            );
          }),
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      // The visual chip stays compact, but the tappable area around it
      // is padded up to ~44pt (Apple HIG minimum touch target).
      child: Padding(
        padding: const EdgeInsets.only(left: 6, top: 9, bottom: 9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
          decoration: BoxDecoration(
            color: const Color(0x0F16162E),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            round.shortLabel,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkFainter,
            ),
          ),
        ),
      ),
    );
  }
}
