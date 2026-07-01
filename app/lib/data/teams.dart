import 'package:flutter/material.dart';

import '../models/team.dart';

/// Every national team referenced by the mock dataset, keyed by its
/// 3-letter code. PT-BR names, flag emoji, and the two primary kit
/// colors used for the at-a-glance color chip.
const Map<String, Team> kTeams = {
  'BRA': Team(code: 'BRA', name: 'Brasil', flag: '🇧🇷', colorA: Color(0xFFFEDD00), colorB: Color(0xFF009B3A)),
  'JPN': Team(code: 'JPN', name: 'Japão', flag: '🇯🇵', colorA: Color(0xFF142A6E), colorB: Color(0xFFBC002D)),
  'FRA': Team(code: 'FRA', name: 'França', flag: '🇫🇷', colorA: Color(0xFF0055A4), colorB: Color(0xFFEF4135)),
  'SEN': Team(code: 'SEN', name: 'Senegal', flag: '🇸🇳', colorA: Color(0xFF00853F), colorB: Color(0xFFFDEF42)),
  'ARG': Team(code: 'ARG', name: 'Argentina', flag: '🇦🇷', colorA: Color(0xFF6CACE4), colorB: Color(0xFFF6B40E)),
  'MEX': Team(code: 'MEX', name: 'México', flag: '🇲🇽', colorA: Color(0xFF006847), colorB: Color(0xFFCE1126)),
  'ESP': Team(code: 'ESP', name: 'Espanha', flag: '🇪🇸', colorA: Color(0xFFAA151B), colorB: Color(0xFFF1BF00)),
  'CRO': Team(code: 'CRO', name: 'Croácia', flag: '🇭🇷', colorA: Color(0xFFC8102E), colorB: Color(0xFF0B4EA2)),
  'ENG': Team(code: 'ENG', name: 'Inglaterra', flag: '🏴', colorA: Color(0xFFCF142B), colorB: Color(0xFFE9EEF5)),
  'SUI': Team(code: 'SUI', name: 'Suíça', flag: '🇨🇭', colorA: Color(0xFFD52B1E), colorB: Color(0xFFE9EEF5)),
  'NED': Team(code: 'NED', name: 'Países Baixos', flag: '🇳🇱', colorA: Color(0xFF21468B), colorB: Color(0xFFF36C21)),
  'USA': Team(code: 'USA', name: 'Estados Unidos', flag: '🇺🇸', colorA: Color(0xFF3C3B6E), colorB: Color(0xFFB22234)),
  'POR': Team(code: 'POR', name: 'Portugal', flag: '🇵🇹', colorA: Color(0xFF006600), colorB: Color(0xFFDA291C)),
  'URU': Team(code: 'URU', name: 'Uruguai', flag: '🇺🇾', colorA: Color(0xFF4977BC), colorB: Color(0xFFF6D800)),
  'GER': Team(code: 'GER', name: 'Alemanha', flag: '🇩🇪', colorA: Color(0xFF1A1A1A), colorB: Color(0xFFDD0000)),
  'COL': Team(code: 'COL', name: 'Colômbia', flag: '🇨🇴', colorA: Color(0xFFFCD116), colorB: Color(0xFF003893)),
  'SRB': Team(code: 'SRB', name: 'Sérvia', flag: '🇷🇸', colorA: Color(0xFF0C4076), colorB: Color(0xFFC6363C)),
  'KOR': Team(code: 'KOR', name: 'Coreia do Sul', flag: '🇰🇷', colorA: Color(0xFF0047A0), colorB: Color(0xFFCD2E3A)),
  'POL': Team(code: 'POL', name: 'Polônia', flag: '🇵🇱', colorA: Color(0xFFDC143C), colorB: Color(0xFFE9EEF5)),
  'AUS': Team(code: 'AUS', name: 'Austrália', flag: '🇦🇺', colorA: Color(0xFF00843D), colorB: Color(0xFFFFCD00)),
  'DEN': Team(code: 'DEN', name: 'Dinamarca', flag: '🇩🇰', colorA: Color(0xFFC60C30), colorB: Color(0xFFE9EEF5)),
  'TUN': Team(code: 'TUN', name: 'Tunísia', flag: '🇹🇳', colorA: Color(0xFFE70013), colorB: Color(0xFFE9EEF5)),
  'GHA': Team(code: 'GHA', name: 'Gana', flag: '🇬🇭', colorA: Color(0xFF006B3F), colorB: Color(0xFFFCD116)),
  'NOR': Team(code: 'NOR', name: 'Noruega', flag: '🇳🇴', colorA: Color(0xFFBA0C2F), colorB: Color(0xFF00205B)),
  'WAL': Team(code: 'WAL', name: 'País de Gales', flag: '🏴', colorA: Color(0xFF00805E), colorB: Color(0xFFC8102E)),
  'IRN': Team(code: 'IRN', name: 'Irã', flag: '🇮🇷', colorA: Color(0xFF239F40), colorB: Color(0xFFDA0000)),
  'ECU': Team(code: 'ECU', name: 'Equador', flag: '🇪🇨', colorA: Color(0xFFFFD100), colorB: Color(0xFF0072CE)),
  'QAT': Team(code: 'QAT', name: 'Catar', flag: '🇶🇦', colorA: Color(0xFF8A1538), colorB: Color(0xFFE9EEF5)),
  'MAR': Team(code: 'MAR', name: 'Marrocos', flag: '🇲🇦', colorA: Color(0xFFC1272D), colorB: Color(0xFF006233)),
  'CRC': Team(code: 'CRC', name: 'Costa Rica', flag: '🇨🇷', colorA: Color(0xFF002B7F), colorB: Color(0xFFCE1126)),
  'NGA': Team(code: 'NGA', name: 'Nigéria', flag: '🇳🇬', colorA: Color(0xFF008751), colorB: Color(0xFFE9EEF5)),
  'KSA': Team(code: 'KSA', name: 'Arábia Saudita', flag: '🇸🇦', colorA: Color(0xFF006C35), colorB: Color(0xFFE9EEF5)),
  'CMR': Team(code: 'CMR', name: 'Camarões', flag: '🇨🇲', colorA: Color(0xFF007A5E), colorB: Color(0xFFCE1126)),
};

Team team(String code) => kTeams[code]!;
