import 'package:flutter/cupertino.dart';

import '../../models/match_event.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_label.dart';
import '../../widgets/surfaces.dart';

class EventsTimeline extends StatelessWidget {
  const EventsTimeline({super.key, required this.events});

  final List<MatchEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('LANCES DO JOGO'),
        const SizedBox(height: 8),
        SoftCard(
          borderRadius: BorderRadius.circular(AppRadii.cardLarge),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [for (final e in events) _EventRow(event: e)],
          ),
        ),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final MatchEvent event;

  @override
  Widget build(BuildContext context) {
    final isA = event.side == MatchSide.a;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: isA
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          event.label,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(event.icon, style: const TextStyle(fontSize: 13)),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(
            width: 48,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0x0F16162E),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "${event.minute}'",
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkFaint,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: !isA
                ? Row(
                    children: [
                      Text(event.icon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          event.label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.ink),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
