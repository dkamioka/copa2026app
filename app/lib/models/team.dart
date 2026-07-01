import 'package:flutter/material.dart';

/// A national team: FIFA-style 3-letter code, PT-BR display name,
/// flag emoji, and its two primary kit colors (used for the
/// at-a-glance color chip when a flag doesn't render well).
@immutable
class Team {
  final String code;
  final String name;
  final String flag;
  final Color colorA;
  final Color colorB;

  const Team({
    required this.code,
    required this.name,
    required this.flag,
    required this.colorA,
    required this.colorB,
  });

  Gradient get chipGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.48, 0.52, 1.0],
        colors: [colorA, colorA, colorB, colorB],
      );

  @override
  bool operator ==(Object other) => other is Team && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// Placeholder "team" used when a bracket slot isn't decided yet,
/// e.g. "Vencedor QF2".
class UnresolvedTeam {
  final String label;
  const UnresolvedTeam(this.label);
}
