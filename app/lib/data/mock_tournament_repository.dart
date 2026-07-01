import '../models/group_standing.dart';
import '../models/head_to_head.dart';
import '../models/match.dart';
import '../models/match_detail.dart';
import '../models/match_event.dart';
import '../models/penalty_shootout.dart';
import '../models/scorer.dart';
import '../models/team.dart';
import 'teams.dart';
import 'tournament_repository.dart';

MatchEvent _e(int min, MatchEventType type, String player, MatchSide side) =>
    MatchEvent(minute: min, type: type, player: player, side: side);

/// Illustrative 2026 knockout-stage dataset, ported 1:1 from the Claude
/// Design prototype. Swap this for an API-backed [TournamentRepository]
/// once a live data provider is wired up — nothing above this class
/// needs to change.
class MockTournamentRepository implements TournamentRepository {
  MockTournamentRepository() {
    _buildMatches();
    _buildStandings();
    _buildScorers();
  }

  final Map<String, Match> _byId = {};
  final Map<Round, List<Match>> _byRound = {
    Round.r16: [],
    Round.qf: [],
    Round.sf: [],
    Round.f: [],
  };
  late final List<GroupStanding> _standings;
  late final List<Scorer> _scorers;

  void _add(Match m) {
    _byId[m.id] = m;
    _byRound[m.round]!.add(m);
  }

  void _buildMatches() {
    _add(Match(
      id: 'r1',
      round: Round.r16,
      teamA: team('BRA'),
      teamB: team('JPN'),
      status: MatchStatus.finished,
      scoreA: 3,
      scoreB: 1,
      venue: 'SoFi Stadium, Los Angeles',
      dateShort: 'Qui, 25/06 · 21:00',
      dateLong: 'Qui, 25/06 · 21:00',
      events: [
        _e(12, MatchEventType.goal, 'Raphinha', MatchSide.a),
        _e(34, MatchEventType.goal, 'Mitoma', MatchSide.b),
        _e(51, MatchEventType.goal, 'Vinícius Jr', MatchSide.a),
        _e(88, MatchEventType.goal, 'Endrick', MatchSide.a),
      ],
    ));
    _add(Match(
      id: 'r2',
      round: Round.r16,
      teamA: team('FRA'),
      teamB: team('SEN'),
      status: MatchStatus.finished,
      scoreA: 2,
      scoreB: 0,
      venue: 'Mercedes-Benz Stadium, Atlanta',
      dateShort: 'Qui, 25/06 · 18:00',
      dateLong: 'Qui, 25/06 · 18:00',
      events: [
        _e(27, MatchEventType.goal, 'Griezmann', MatchSide.a),
        _e(69, MatchEventType.goal, 'Mbappé', MatchSide.a),
      ],
    ));
    _add(Match(
      id: 'r3',
      round: Round.r16,
      teamA: team('ARG'),
      teamB: team('MEX'),
      status: MatchStatus.finished,
      scoreA: 2,
      scoreB: 1,
      venue: 'AT&T Stadium, Dallas',
      dateShort: 'Sex, 26/06 · 21:00',
      dateLong: 'Sex, 26/06 · 21:00',
      events: [
        _e(9, MatchEventType.goal, 'Messi', MatchSide.a),
        _e(44, MatchEventType.goal, 'L. Martínez', MatchSide.a),
        _e(73, MatchEventType.goal, 'R. Jiménez', MatchSide.b),
      ],
    ));
    _add(Match(
      id: 'r4',
      round: Round.r16,
      teamA: team('ESP'),
      teamB: team('CRO'),
      status: MatchStatus.finished,
      scoreA: 4,
      scoreB: 2,
      venue: 'NRG Stadium, Houston',
      dateShort: 'Sex, 26/06 · 18:00',
      dateLong: 'Sex, 26/06 · 18:00',
      events: [
        _e(15, MatchEventType.goal, 'Morata', MatchSide.a),
        _e(31, MatchEventType.goal, 'Kramarić', MatchSide.b),
        _e(40, MatchEventType.goal, 'Yamal', MatchSide.a),
        _e(58, MatchEventType.goal, 'Dani Olmo', MatchSide.a),
        _e(70, MatchEventType.goal, 'Budimir', MatchSide.b),
        _e(82, MatchEventType.goal, 'Oyarzabal', MatchSide.a),
      ],
    ));
    _add(Match(
      id: 'r5',
      round: Round.r16,
      teamA: team('ENG'),
      teamB: team('SUI'),
      status: MatchStatus.finished,
      scoreA: 1,
      scoreB: 0,
      venue: 'Lincoln Financial Field, Filadélfia',
      dateShort: 'Sáb, 27/06 · 21:00',
      dateLong: 'Sáb, 27/06 · 21:00',
      events: [
        _e(62, MatchEventType.goal, 'Kane', MatchSide.a),
        _e(78, MatchEventType.yellowCard, 'Rice', MatchSide.a),
      ],
    ));
    _add(Match(
      id: 'r6',
      round: Round.r16,
      teamA: team('NED'),
      teamB: team('USA'),
      status: MatchStatus.finished,
      scoreA: 2,
      scoreB: 1,
      venue: 'Lumen Field, Seattle',
      dateShort: 'Sáb, 27/06 · 18:00',
      dateLong: 'Sáb, 27/06 · 18:00',
      events: [
        _e(31, MatchEventType.goal, 'Gakpo', MatchSide.a),
        _e(55, MatchEventType.goal, 'Pulisic', MatchSide.b),
        _e(78, MatchEventType.goal, 'Depay', MatchSide.a),
      ],
    ));
    _add(Match(
      id: 'r7',
      round: Round.r16,
      teamA: team('POR'),
      teamB: team('URU'),
      status: MatchStatus.finished,
      scoreA: 3,
      scoreB: 2,
      venue: 'Hard Rock Stadium, Miami',
      dateShort: 'Dom, 28/06 · 21:00',
      dateLong: 'Dom, 28/06 · 21:00',
      events: [
        _e(5, MatchEventType.goal, 'Ronaldo', MatchSide.a),
        _e(29, MatchEventType.goal, 'Núñez', MatchSide.b),
        _e(47, MatchEventType.goal, 'B. Fernandes', MatchSide.a),
        _e(63, MatchEventType.goal, 'Valverde', MatchSide.b),
        _e(90, MatchEventType.goal, 'Leão', MatchSide.a),
      ],
    ));
    _add(Match(
      id: 'r8',
      round: Round.r16,
      teamA: team('GER'),
      teamB: team('COL'),
      status: MatchStatus.finished,
      scoreA: 2,
      scoreB: 1,
      venue: "Levi's Stadium, San Francisco",
      dateShort: 'Dom, 28/06 · 18:00',
      dateLong: 'Dom, 28/06 · 18:00',
      events: [
        _e(40, MatchEventType.goal, 'Havertz', MatchSide.a),
        _e(66, MatchEventType.goal, 'Wirtz', MatchSide.a),
        _e(81, MatchEventType.goal, 'J. Rodríguez', MatchSide.b),
      ],
    ));

    _add(Match(
      id: 'q1',
      round: Round.qf,
      teamA: team('BRA'),
      teamB: team('FRA'),
      status: MatchStatus.finished,
      scoreA: 1,
      scoreB: 1,
      penalties: const PenaltyShootout(
        teamA: [true, true, true, true],
        teamB: [true, false, true, false],
        winner: MatchSide.a,
      ),
      venue: 'Mercedes-Benz Stadium, Atlanta',
      dateShort: 'Ter, 30/06 · 21:00',
      dateLong: 'Ter, 30/06 · 21:00',
      events: [
        _e(23, MatchEventType.goal, 'Vinícius Jr', MatchSide.a),
        _e(41, MatchEventType.yellowCard, 'Casemiro', MatchSide.a),
        _e(58, MatchEventType.penaltyGoal, 'Mbappé', MatchSide.b),
        _e(84, MatchEventType.redCard, 'Mendy', MatchSide.b),
      ],
    ));
    _add(Match(
      id: 'q2',
      round: Round.qf,
      teamA: team('ARG'),
      teamB: team('ESP'),
      status: MatchStatus.live,
      scoreA: 1,
      scoreB: 1,
      liveMinute: "67'",
      venue: 'Hard Rock Stadium, Miami',
      dateShort: 'Hoje · 18:00',
      dateLong: 'Hoje · 18:00',
      events: [
        _e(19, MatchEventType.goal, 'L. Martínez', MatchSide.a),
        _e(38, MatchEventType.yellowCard, 'Yamal', MatchSide.b),
        _e(55, MatchEventType.goal, 'Yamal', MatchSide.b),
      ],
    ));
    _add(Match(
      id: 'q3',
      round: Round.qf,
      teamA: team('ENG'),
      teamB: team('NED'),
      status: MatchStatus.upcoming,
      venue: 'MetLife Stadium, Nova York',
      dateShort: 'Hoje · 21:00',
      dateLong: 'Hoje · 21:00',
    ));
    _add(Match(
      id: 'q4',
      round: Round.qf,
      teamA: team('POR'),
      teamB: team('GER'),
      status: MatchStatus.upcoming,
      venue: 'AT&T Stadium, Dallas',
      dateShort: 'Amanhã · 21:00',
      dateLong: 'Amanhã, 02/07 · 21:00',
    ));

    _add(Match(
      id: 's1',
      round: Round.sf,
      teamA: team('BRA'),
      teamB: null,
      placeholderB: 'Vencedor QF2',
      status: MatchStatus.upcoming,
      venue: 'AT&T Stadium, Dallas',
      dateShort: 'Sáb · 04/07',
      dateLong: 'Sáb, 04/07 · 20:00',
    ));
    _add(const Match(
      id: 's2',
      round: Round.sf,
      teamA: null,
      teamB: null,
      placeholderA: 'Vencedor QF3',
      placeholderB: 'Vencedor QF4',
      status: MatchStatus.upcoming,
      venue: 'MetLife Stadium, Nova York',
      dateShort: 'Dom · 05/07',
      dateLong: 'Dom, 05/07 · 20:00',
    ));

    _add(const Match(
      id: 'f1',
      round: Round.f,
      teamA: null,
      teamB: null,
      placeholderA: 'Vencedor SF1',
      placeholderB: 'Vencedor SF2',
      status: MatchStatus.upcoming,
      venue: 'MetLife Stadium, Nova York',
      dateShort: 'Dom · 12/07',
      dateLong: 'Dom, 12/07 · 16:00',
    ));
  }

  void _buildStandings() {
    const raw = <String, List<List<Object>>>{
      'Grupo A': [
        ['BRA', 9, 3, 3, 0, 0, 6],
        ['MEX', 6, 3, 2, 0, 1, 2],
        ['SRB', 3, 3, 1, 0, 2, -3],
        ['KOR', 0, 3, 0, 0, 3, -5],
      ],
      'Grupo B': [
        ['ARG', 9, 3, 3, 0, 0, 5],
        ['JPN', 6, 3, 2, 0, 1, 1],
        ['POL', 3, 3, 1, 0, 2, -2],
        ['AUS', 0, 3, 0, 0, 3, -4],
      ],
      'Grupo C': [
        ['FRA', 7, 3, 2, 1, 0, 4],
        ['CRO', 5, 3, 1, 2, 0, 2],
        ['DEN', 4, 3, 1, 1, 1, 0],
        ['TUN', 0, 3, 0, 0, 3, -6],
      ],
      'Grupo D': [
        ['ESP', 9, 3, 3, 0, 0, 6],
        ['SEN', 4, 3, 1, 1, 1, 0],
        ['GHA', 3, 3, 1, 0, 2, -2],
        ['NOR', 1, 3, 0, 1, 2, -4],
      ],
      'Grupo E': [
        ['ENG', 7, 3, 2, 1, 0, 4],
        ['USA', 5, 3, 1, 2, 0, 1],
        ['WAL', 3, 3, 1, 0, 2, -2],
        ['IRN', 1, 3, 0, 1, 2, -3],
      ],
      'Grupo F': [
        ['NED', 7, 3, 2, 1, 0, 4],
        ['SUI', 5, 3, 1, 2, 0, 1],
        ['ECU', 4, 3, 1, 1, 1, 0],
        ['QAT', 1, 3, 0, 1, 2, -3],
      ],
      'Grupo G': [
        ['POR', 9, 3, 3, 0, 0, 5],
        ['COL', 6, 3, 2, 0, 1, 2],
        ['MAR', 4, 3, 1, 1, 1, -1],
        ['CRC', 0, 3, 0, 0, 3, -6],
      ],
      'Grupo H': [
        ['GER', 7, 3, 2, 1, 0, 3],
        ['URU', 6, 3, 2, 0, 1, 2],
        ['NGA', 3, 3, 1, 0, 2, -1],
        ['KSA', 1, 3, 0, 1, 2, -4],
      ],
    };

    _standings = raw.entries.map((entry) {
      final rows = <GroupStandingRow>[];
      for (var i = 0; i < entry.value.length; i++) {
        final r = entry.value[i];
        rows.add(GroupStandingRow(
          team: team(r[0] as String),
          points: r[1] as int,
          played: r[2] as int,
          wins: r[3] as int,
          draws: r[4] as int,
          losses: r[5] as int,
          goalDiff: r[6] as int,
          qualified: i < 2,
        ));
      }
      return GroupStanding(letter: entry.key, rows: rows);
    }).toList();
  }

  void _buildScorers() {
    const raw = [
      ['Kylian Mbappé', 'FRA', 6],
      ['Harry Kane', 'ENG', 5],
      ['Vinícius Jr', 'BRA', 4],
      ['Lautaro Martínez', 'ARG', 4],
      ['Lamine Yamal', 'ESP', 3],
      ['Cristiano Ronaldo', 'POR', 3],
      ['Cody Gakpo', 'NED', 3],
      ['Jamal Musiala', 'GER', 2],
    ];
    _scorers = [
      for (var i = 0; i < raw.length; i++)
        Scorer(
          rank: i + 1,
          player: raw[i][0] as String,
          team: team(raw[i][1] as String),
          goals: raw[i][2] as int,
        ),
    ];
  }

  static const Map<String, ({String group, String stat, List<(GameResult, String, String)> games})>
      _groupCampaigns = {
    'BRA': (group: 'Grupo A · 1º', stat: '3J · 3V 0E 0D · 9 pts', games: [(GameResult.win, '3-0', 'SRB'), (GameResult.win, '2-0', 'KOR'), (GameResult.win, '2-1', 'CMR')]),
    'JPN': (group: 'Grupo B · 2º', stat: '3J · 2V 0E 1D · 6 pts', games: [(GameResult.win, '2-1', 'POL'), (GameResult.loss, '0-2', 'ARG'), (GameResult.win, '2-0', 'AUS')]),
    'FRA': (group: 'Grupo C · 1º', stat: '3J · 2V 1E 0D · 7 pts', games: [(GameResult.win, '2-0', 'DEN'), (GameResult.draw, '1-1', 'CRO'), (GameResult.win, '3-1', 'TUN')]),
    'SEN': (group: 'Grupo D · 2º', stat: '3J · 1V 1E 1D · 4 pts', games: [(GameResult.win, '2-1', 'GHA'), (GameResult.loss, '0-2', 'ESP'), (GameResult.draw, '1-1', 'NOR')]),
    'ARG': (group: 'Grupo B · 1º', stat: '3J · 3V 0E 0D · 9 pts', games: [(GameResult.win, '2-0', 'AUS'), (GameResult.win, '2-0', 'JPN'), (GameResult.win, '2-1', 'POL')]),
    'MEX': (group: 'Grupo A · 2º', stat: '3J · 2V 0E 1D · 6 pts', games: [(GameResult.win, '2-1', 'KOR'), (GameResult.loss, '0-2', 'BRA'), (GameResult.win, '2-0', 'SRB')]),
    'ESP': (group: 'Grupo D · 1º', stat: '3J · 3V 0E 0D · 9 pts', games: [(GameResult.win, '2-0', 'SEN'), (GameResult.win, '3-1', 'GHA'), (GameResult.win, '2-1', 'NOR')]),
    'CRO': (group: 'Grupo C · 2º', stat: '3J · 1V 2E 0D · 5 pts', games: [(GameResult.draw, '1-1', 'FRA'), (GameResult.win, '4-1', 'TUN'), (GameResult.draw, '0-0', 'DEN')]),
    'ENG': (group: 'Grupo E · 1º', stat: '3J · 2V 1E 0D · 7 pts', games: [(GameResult.win, '2-0', 'IRN'), (GameResult.draw, '1-1', 'USA'), (GameResult.win, '3-1', 'WAL')]),
    'SUI': (group: 'Grupo F · 2º', stat: '3J · 1V 2E 0D · 5 pts', games: [(GameResult.win, '3-2', 'ECU'), (GameResult.draw, '1-1', 'NED'), (GameResult.draw, '0-0', 'QAT')]),
    'NED': (group: 'Grupo F · 1º', stat: '3J · 2V 1E 0D · 7 pts', games: [(GameResult.win, '2-0', 'QAT'), (GameResult.draw, '1-1', 'SUI'), (GameResult.win, '3-1', 'ECU')]),
    'USA': (group: 'Grupo E · 2º', stat: '3J · 1V 2E 0D · 5 pts', games: [(GameResult.draw, '1-1', 'WAL'), (GameResult.draw, '1-1', 'ENG'), (GameResult.win, '1-0', 'IRN')]),
    'POR': (group: 'Grupo G · 1º', stat: '3J · 3V 0E 0D · 9 pts', games: [(GameResult.win, '3-2', 'MAR'), (GameResult.win, '2-0', 'CRC'), (GameResult.win, '1-0', 'COL')]),
    'URU': (group: 'Grupo H · 2º', stat: '3J · 2V 0E 1D · 6 pts', games: [(GameResult.win, '2-0', 'KSA'), (GameResult.loss, '0-1', 'GER'), (GameResult.win, '3-1', 'NGA')]),
    'GER': (group: 'Grupo H · 1º', stat: '3J · 2V 1E 0D · 7 pts', games: [(GameResult.win, '4-1', 'NGA'), (GameResult.win, '1-0', 'URU'), (GameResult.draw, '1-1', 'KSA')]),
    'COL': (group: 'Grupo G · 2º', stat: '3J · 2V 0E 1D · 6 pts', games: [(GameResult.win, '2-0', 'CRC'), (GameResult.loss, '0-1', 'POR'), (GameResult.win, '1-0', 'MAR')]),
  };

  static const Map<String, List<(String, String)>> _teamNews = {
    'BRA': [('➕', 'Alex Sandro fora (lesão na coxa) — Militão atua na lateral'), ('🟨', 'Casemiro pendurado, a um amarelo da suspensão')],
    'FRA': [('🟥', 'Ferland Mendy suspenso — expulso contra o Brasil'), ('➕', 'Ousmane Dembélé é dúvida (coxa)')],
    'ARG': [('🟨', 'Mac Allister pendurado, arrisca suspensão'), ('➕', 'Ángel Di María recuperado, deve começar')],
    'ESP': [('🟨', 'Le Normand a um amarelo da suspensão'), ('➕', 'Pedri passou em teste físico de última hora')],
    'ENG': [('🟥', 'Declan Rice suspenso — acúmulo de cartões amarelos'), ('➕', 'Bukayo Saka volta de lesão')],
    'NED': [('➕', 'Frenkie de Jong é grande dúvida (panturrilha)'), ('🟨', 'Virgil van Dijk pendurado')],
    'POR': [('🟨', 'Bruno Fernandes a um amarelo da suspensão'), ('➕', 'João Cancelo recuperado')],
    'GER': [('🟥', 'Antonio Rüdiger suspenso — expulso contra a Colômbia'), ('➕', 'Jamal Musiala volta aos treinos')],
    'JPN': [('🟨', 'Wataru Endō pendurado contra o Brasil'), ('➕', 'Restante do elenco à disposição')],
    'SEN': [('➕', 'Sem novos problemas físicos'), ('🟨', 'Pape Sarr pendurado')],
    'MEX': [('➕', 'Elenco completo à disposição')],
    'CRO': [('➕', 'Time-base totalmente recuperado')],
    'SUI': [('🟨', 'Granit Xhaka foi advertido')],
    'USA': [('➕', 'Elenco completo à disposição')],
    'URU': [('🟥', 'Zagueiro suspenso para a próxima fase')],
    'COL': [('➕', 'Sem problemas de lesão no elenco')],
  };

  static const Map<String, List<(String, String, String)>> _h2hMap = {
    'BRA-FRA': [('🇫🇷 1 – 0 🇧🇷', 'Copa do Mundo · Quartas', '01 Jul 2006'), ('🇫🇷 3 – 0 🇧🇷', 'Copa do Mundo · Final', '12 Jul 1998'), ('🇧🇷 3 – 0 🇫🇷', 'Amistoso', '09 Jun 2013'), ('🇫🇷 1 – 1 🇧🇷', 'Amistoso', '26 Mar 2015')],
    'ARG-ESP': [('🇪🇸 6 – 1 🇦🇷', 'Amistoso', '13 Nov 2018'), ('🇦🇷 4 – 1 🇪🇸', 'Amistoso', '07 Set 2010'), ('🇪🇸 2 – 1 🇦🇷', 'Amistoso', '03 Mar 2010')],
    'ENG-NED': [('🇳🇱 2 – 1 🏴', 'Eurocopa 2024 · Semi', '10 Jul 2024'), ('🏴 0 – 0 🇳🇱', 'Amistoso', '23 Mar 2018'), ('🇳🇱 3 – 1 🏴', 'Eurocopa 1988', '15 Jun 1988')],
    'POR-GER': [('🇩🇪 4 – 2 🇵🇹', 'Copa do Mundo 2014', '16 Jun 2014'), ('🇩🇪 4 – 2 🇵🇹', 'Eurocopa 2020', '19 Jun 2021'), ('🇵🇹 1 – 0 🇩🇪', 'Eurocopa 2000', '20 Jun 2000')],
    'BRA-JPN': [('🇧🇷 1 – 0 🇯🇵', 'Amistoso', '10 Jul 2022'), ('🇧🇷 4 – 0 🇯🇵', 'Amistoso', '10 Nov 2017'), ('🇯🇵 2 – 2 🇧🇷', 'Copa das Confederações', '22 Jun 2005')],
  };

  @override
  Future<void> refresh() async {
    // Mock data is already in memory — nothing to load.
  }

  @override
  List<Match> matchesByRound(Round round) => List.unmodifiable(_byRound[round]!);

  @override
  Match? matchById(String id) => _byId[id];

  @override
  Match? get liveMatch => _byId['q2'];

  @override
  List<GroupStanding> get groupStandings => _standings;

  @override
  List<Scorer> get topScorers => _scorers;

  @override
  Future<MatchDetail> loadMatchDetail(Match match) async {
    final a = match.teamA;
    final b = match.teamB;
    if (match.isTbd || a == null || b == null) {
      return MatchDetail(events: match.events);
    }
    return MatchDetail(
      events: match.events,
      headToHead: _headToHead(a, b),
      formA: _groupFormFor(a),
      formB: _groupFormFor(b),
      newsA: _teamNewsFor(a),
      newsB: _teamNewsFor(b),
    );
  }

  TeamGroupForm _groupFormFor(Team team) {
    final c = _groupCampaigns[team.code];
    if (c == null) {
      return TeamGroupForm(team: team, groupLabel: '', statLine: '', games: const []);
    }
    return TeamGroupForm(
      team: team,
      groupLabel: c.group,
      statLine: c.stat,
      games: [
        for (final g in c.games)
          GroupFormGame(result: g.$1, score: g.$2, opponent: kTeams[g.$3] ?? team),
      ],
    );
  }

  List<HeadToHead> _headToHead(Team a, Team b) {
    final key = _h2hMap['${a.code}-${b.code}'] ?? _h2hMap['${b.code}-${a.code}'];
    final entries = key ??
        [
          ('${a.flag} 1 – 0 ${b.flag}', 'Amistoso', 'Nov 2023'),
          ('${b.flag} 2 – 2 ${a.flag}', 'Amistoso', 'Jun 2019'),
          ('${a.flag} 0 – 1 ${b.flag}', 'Amistoso', 'Mar 2014'),
        ];
    return [
      for (final e in entries) HeadToHead(fixture: e.$1, competition: e.$2, date: e.$3),
    ];
  }

  List<TeamNewsItem> _teamNewsFor(Team team) {
    final items = _teamNews[team.code] ?? const [('➕', 'Elenco à disposição')];
    return [for (final i in items) TeamNewsItem(icon: i.$1, text: i.$2)];
  }
}
