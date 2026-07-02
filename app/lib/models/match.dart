import 'match_event.dart';
import 'penalty_shootout.dart';
import 'team.dart';

enum Round { r16, qf, sf, f }

extension RoundLabels on Round {
  String get shortLabel => switch (this) {
        Round.r16 => 'Oitavas',
        Round.qf => 'Quartas',
        Round.sf => 'Semifinais',
        Round.f => 'Final',
      };

  String get fullLabel => switch (this) {
        Round.r16 => 'Oitavas de Final',
        Round.qf => 'Quartas de Final',
        Round.sf => 'Semifinal',
        Round.f => 'Final',
      };
}

enum MatchStatus { upcoming, live, finished }

class Match {
  final String id;
  final Round round;

  /// Null when the slot isn't decided yet (e.g. still waiting on a
  /// previous round). [placeholderA]/[placeholderB] hold text like
  /// "Vencedor QF2" in that case.
  final Team? teamA;
  final Team? teamB;
  final String? placeholderA;
  final String? placeholderB;

  final MatchStatus status;
  final int? scoreA;
  final int? scoreB;
  final String? liveMinute;
  final PenaltyShootout? penalties;

  final String venue;

  /// Short label for the bracket card footer, e.g. "Amanhã · 21:00".
  final String dateShort;

  /// Full label for the match detail header, e.g. "Amanhã, 02/07 · 21:00".
  final String dateLong;

  final List<MatchEvent> events;

  const Match({
    required this.id,
    required this.round,
    this.teamA,
    this.teamB,
    this.placeholderA,
    this.placeholderB,
    required this.status,
    this.scoreA,
    this.scoreB,
    this.liveMinute,
    this.penalties,
    required this.venue,
    required this.dateShort,
    required this.dateLong,
    this.events = const [],
  });

  bool get isTbd => teamA == null || teamB == null;
  bool get isFinished => status == MatchStatus.finished;
  bool get isLive => status == MatchStatus.live;

  String get nameA => teamA?.name ?? placeholderA ?? 'A definir';
  String get nameB => teamB?.name ?? placeholderB ?? 'A definir';
  String get flagA => teamA?.flag ?? '⚪';
  String get flagB => teamB?.flag ?? '⚪';

  /// Winner side, if the result is decided (regular time or penalties).
  MatchSide? get winner {
    if (!isFinished) return null;
    if (penalties != null) return penalties!.winner;
    if (scoreA == null || scoreB == null || scoreA == scoreB) return null;
    return scoreA! > scoreB! ? MatchSide.a : MatchSide.b;
  }

  bool get isDraw =>
      isFinished && penalties == null && scoreA != null && scoreA == scoreB;

  String get scoreLabelA =>
      (isFinished || isLive) && scoreA != null ? '$scoreA' : '';
  String get scoreLabelB =>
      (isFinished || isLive) && scoreB != null ? '$scoreB' : '';

  /// Footer label shown on the compact bracket card. The live minute is
  /// omitted when the data source doesn't provide one.
  String get footerLabel {
    if (isFinished) {
      return penalties != null
          ? 'Pên · ${penalties!.scoreA}-${penalties!.scoreB}'
          : 'Encerrado';
    }
    if (isLive) {
      return liveMinute != null ? '● Ao vivo · $liveMinute' : '● Ao vivo';
    }
    return dateShort;
  }

  /// Hero score line for the detail header. A live match can briefly
  /// have no goal data yet (feed lag right after kickoff) — show 0-0
  /// rather than "null".
  String get heroScore =>
      (isFinished || isLive) ? '${scoreA ?? 0}  –  ${scoreB ?? 0}' : 'vs';

  String get statusLabel {
    if (isFinished) return penalties != null ? 'Encerrado · pên.' : 'Encerrado';
    if (isLive) return liveMinute != null ? 'Ao vivo · $liveMinute' : 'Ao vivo';
    return dateLong;
  }
}
