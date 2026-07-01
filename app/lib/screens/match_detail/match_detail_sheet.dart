import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../data/tournament_repository.dart';
import '../../models/match.dart';
import '../../models/match_detail.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_label.dart';
import '../../widgets/surfaces.dart';
import 'events_timeline.dart';
import 'group_form_card.dart';
import 'h2h_carousel.dart';
import 'penalty_section.dart';
import 'score_header.dart';
import 'team_news_card.dart';

/// Presents the match detail as a Cupertino-native sheet — a bespoke
/// [PageRoute] rather than Material's `showModalBottomSheet`, which
/// requires `MaterialLocalizations` that a pure `CupertinoApp` doesn't
/// provide.
Future<void> showMatchDetailSheet(
  BuildContext context,
  TournamentRepository repository,
  Match match,
) {
  HapticFeedback.mediumImpact();
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x4714162C),
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return MatchDetailSheet(repository: repository, match: match);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.32, 0.72, 0, 1),
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
          child: child,
        );
      },
    ),
  );
}

class MatchDetailSheet extends StatefulWidget {
  const MatchDetailSheet({super.key, required this.repository, required this.match});

  final TournamentRepository repository;
  final Match match;

  @override
  State<MatchDetailSheet> createState() => _MatchDetailSheetState();
}

class _MatchDetailSheetState extends State<MatchDetailSheet> {
  late final Future<MatchDetail> _detail =
      widget.repository.loadMatchDetail(widget.match);

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final height = MediaQuery.of(context).size.height * 0.91;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              color: const Color(0xC7FFFFFF),
              child: Column(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 11, bottom: 6),
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0x3816162E),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(20, 6, 20, 24 + MediaQuery.of(context).padding.bottom),
                      children: [
                        ScoreHeader(match: match),
                        const SizedBox(height: 18),
                        if (match.isTbd)
                          SoftCard(
                            borderRadius: BorderRadius.circular(18),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            child: const Text(
                              'Os times serão definidos ao fim da rodada anterior.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint, height: 1.5),
                            ),
                          ),
                        if (match.penalties != null) ...[
                          PenaltySection(match: match),
                          const SizedBox(height: 18),
                        ],
                        _DetailSections(match: match, future: _detail),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The lower half of the sheet (goal timeline, H2H, group campaign,
/// team news) loads asynchronously — instant for the mock, a network
/// round-trip for the live API. Shows a slim spinner while in flight.
class _DetailSections extends StatelessWidget {
  const _DetailSections({required this.match, required this.future});

  final Match match;
  final Future<MatchDetail> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MatchDetail>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        final detail = snapshot.data ?? MatchDetail.empty;
        final teamA = match.teamA;
        final teamB = match.teamB;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (detail.events.isNotEmpty) ...[
              EventsTimeline(events: detail.events),
              const SizedBox(height: 18),
            ],
            if (detail.headToHead.isNotEmpty) ...[
              H2hCarousel(items: detail.headToHead),
              const SizedBox(height: 18),
            ],
            if (detail.formA != null && detail.formB != null) ...[
              const SectionLabel('CAMPANHA NOS GRUPOS'),
              const SizedBox(height: 8),
              GroupFormCard(form: detail.formA!),
              const SizedBox(height: 10),
              GroupFormCard(form: detail.formB!),
              const SizedBox(height: 18),
            ],
            if (teamA != null && detail.newsA.isNotEmpty || teamB != null && detail.newsB.isNotEmpty) ...[
              const SectionLabel('DESFALQUES & NOVIDADES'),
              const SizedBox(height: 8),
              if (teamA != null && detail.newsA.isNotEmpty)
                TeamNewsCard(team: teamA, items: detail.newsA),
              if (teamA != null && detail.newsA.isNotEmpty && teamB != null && detail.newsB.isNotEmpty)
                const SizedBox(height: 10),
              if (teamB != null && detail.newsB.isNotEmpty)
                TeamNewsCard(team: teamB, items: detail.newsB),
            ],
          ],
        );
      },
    );
  }
}
