import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../models/match.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_surface_pulse.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/team_chip.dart';

/// The live match clock is mock data, but a static "67'" reads dead the
/// moment you glance at it twice. This nudges the displayed minute
/// forward while the banner is on screen so the app feels alive even
/// before it's wired to a real live-score feed.
class LiveMatchBanner extends StatefulWidget {
  const LiveMatchBanner({super.key, required this.match, required this.onTap});

  final Match match;
  final VoidCallback onTap;

  @override
  State<LiveMatchBanner> createState() => _LiveMatchBannerState();
}

class _LiveMatchBannerState extends State<LiveMatchBanner> {
  late int _minute = int.tryParse(widget.match.liveMinute?.replaceAll("'", '') ?? '') ?? 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_minute >= 90) return;
      setState(() => _minute++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: GlassSurface(
        opacity: 0.62,
        blurSigma: 26,
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
        child: Row(
          children: [
            const PulsingDot(color: AppColors.accent, size: 8),
            const SizedBox(width: 9),
            const Text(
              'AO VIVO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppColors.accent,
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TeamColorChip(team: match.teamA, size: 11),
                  const SizedBox(width: 7),
                  TeamFlag(flag: match.flagA, size: 14),
                  const SizedBox(width: 6),
                  Text(match.teamA?.code ?? '', style: _label),
                  const SizedBox(width: 7),
                  Text(
                    '${match.scoreA} – ${match.scoreB}',
                    style: _label.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(match.teamB?.code ?? '', style: _label),
                  const SizedBox(width: 6),
                  TeamFlag(flag: match.flagB, size: 14),
                  const SizedBox(width: 7),
                  TeamColorChip(team: match.teamB, size: 11),
                ],
              ),
            ),
            Text(
              "$_minute'",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
}
