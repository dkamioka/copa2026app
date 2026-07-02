import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'surfaces.dart';

/// Friendly "no data yet" card used by the tab views when the live feed
/// legitimately has nothing to show (e.g. standings before the first
/// round, scorers before the first goal).
class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.message,
  });

  final String emoji;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      borderRadius: BorderRadius.circular(AppRadii.cardLarge),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.inkFaint, height: 1.5),
          ),
        ],
      ),
    );
  }
}
