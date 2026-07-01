import 'package:flutter/cupertino.dart';

import '../../models/head_to_head.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_label.dart';
import '../../widgets/surfaces.dart';

class H2hCarousel extends StatelessWidget {
  const H2hCarousel({super.key, required this.items});

  final List<HeadToHead> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionLabel('CONFRONTOS DIRETOS'),
            Text('arraste →', style: TextStyle(fontSize: 10, color: AppColors.ink.withValues(alpha: 0.4))),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, i) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final h = items[i];
              return SoftCard(
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.all(13),
                child: SizedBox(
                  width: 148,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h.competition.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.inkFainter,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        h.fixture,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(h.date, style: const TextStyle(fontSize: 10, color: AppColors.inkFainter)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
