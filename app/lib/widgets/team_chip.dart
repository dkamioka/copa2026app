import 'package:flutter/material.dart';

import '../models/team.dart';

/// The small rounded color swatch (team's two kit colors) shown before
/// every flag/name — lets you recognize a team at a glance even when
/// the flag emoji doesn't render cleanly.
class TeamColorChip extends StatelessWidget {
  const TeamColorChip({super.key, required this.team, this.size = 10});

  final Team? team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = team;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: t?.chipGradient,
        color: t == null ? const Color(0x2616162E) : null,
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
    );
  }
}

/// Flag emoji at a given font size — factored out so we can keep flag
/// sizing consistent across cards/sheet without repeating TextStyles.
class TeamFlag extends StatelessWidget {
  const TeamFlag({super.key, required this.flag, this.size = 13});

  final String flag;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(flag, style: TextStyle(fontSize: size, height: 1));
  }
}
