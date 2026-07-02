import 'package:flutter/material.dart';

import '../../models/team.dart';
import '../teams.dart';

/// Resolves an API-Football team (identified by its English name) to the
/// app's [Team] value — which carries the PT-BR name, flag emoji and kit
/// colors used throughout the UI.
///
/// API-Football fixtures/standings identify teams by numeric id + English
/// name + a logo URL, but not by the 3-letter code or emoji flag the app
/// renders. We map by normalized English name into [kTeams]; teams not in
/// that table (rare in the knockout stage) fall back to a neutral chip
/// with the API-provided name so nothing breaks.
abstract final class TeamLookup {
  /// Normalized English name → app 3-letter code.
  static const Map<String, String> _englishToCode = {
    'brazil': 'BRA',
    'japan': 'JPN',
    'france': 'FRA',
    'senegal': 'SEN',
    'argentina': 'ARG',
    'mexico': 'MEX',
    'spain': 'ESP',
    'croatia': 'CRO',
    'england': 'ENG',
    'switzerland': 'SUI',
    'netherlands': 'NED',
    'usa': 'USA',
    'unitedstates': 'USA',
    'portugal': 'POR',
    'uruguay': 'URU',
    'germany': 'GER',
    'colombia': 'COL',
    'serbia': 'SRB',
    'korearepublic': 'KOR',
    'southkorea': 'KOR',
    'poland': 'POL',
    'australia': 'AUS',
    'denmark': 'DEN',
    'tunisia': 'TUN',
    'ghana': 'GHA',
    'norway': 'NOR',
    'wales': 'WAL',
    'iran': 'IRN',
    'ecuador': 'ECU',
    'qatar': 'QAT',
    'morocco': 'MAR',
    'costarica': 'CRC',
    'nigeria': 'NGA',
    'saudiarabia': 'KSA',
    'cameroon': 'CMR',
    'canada': 'CAN',
    'belgium': 'BEL',
    'italy': 'ITA',
    'austria': 'AUT',
    'scotland': 'SCO',
    'egypt': 'EGY',
    'algeria': 'ALG',
    // API/e feed spellings vary: "Ivory Coast" and "Côte d'Ivoire"
    // (the latter normalizes with the accented ô stripped).
    'ivorycoast': 'CIV',
    'cotedivoire': 'CIV',
    'ctedivoire': 'CIV',
    'panama': 'PAN',
    'paraguay': 'PAR',
    'uzbekistan': 'UZB',
    'jordan': 'JOR',
    'newzealand': 'NZL',
    'southafrica': 'RSA',
    'capeverde': 'CPV',
    'capeverdeislands': 'CPV',
  };

  static String _normalize(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

  /// Returns the app [Team] for an English team name, or a neutral
  /// fallback team carrying [apiName] if it isn't in the table.
  static Team resolve(String apiName) {
    final code = _englishToCode[_normalize(apiName)];
    if (code != null) return team(code);
    return Team(
      code: apiName.length >= 3 ? apiName.substring(0, 3).toUpperCase() : apiName.toUpperCase(),
      name: apiName,
      flag: '🏳️',
      colorA: const Color(0xFF9AA3B2),
      colorB: const Color(0xFFCBD2DE),
    );
  }
}
