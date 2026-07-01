import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'surfaces.dart';

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      opacity: 0.55,
      blurSigma: 22,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? CupertinoColors.white
                        : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: i == selectedIndex
                        ? [
                            BoxShadow(
                              color: const Color(0xFF1E1E46).withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i == selectedIndex
                          ? AppColors.ink
                          : AppColors.ink.withValues(alpha: 0.55),
                    ),
                    textAlign: TextAlign.center,
                    child: Text(labels[i], textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
