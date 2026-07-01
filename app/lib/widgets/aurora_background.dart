import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Soft, slowly-drifting color blobs behind the content — the "liquid
/// glass" backdrop from the design. Blurred once as a single group
/// (rather than per-card) so it stays smooth on real devices.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 30))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.bgBase,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                return ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Stack(
                    children: [
                      _blob(
                        alignment: Alignment.lerp(
                          const Alignment(-1.2, -1.15),
                          const Alignment(-0.7, -0.7),
                          t,
                        )!,
                        size: 0.85,
                        color: AppColors.blob1,
                      ),
                      _blob(
                        alignment: Alignment.lerp(
                          const Alignment(1.25, 1.2),
                          const Alignment(0.75, 0.85),
                          t,
                        )!,
                        size: 0.95,
                        color: AppColors.blob2,
                      ),
                      _blob(
                        alignment: Alignment.lerp(
                          const Alignment(-0.6, 1.15),
                          const Alignment(-0.1, 0.75),
                          1 - t,
                        )!,
                        size: 0.75,
                        color: AppColors.blob3,
                      ),
                      _blob(
                        alignment: Alignment.lerp(
                          const Alignment(1.1, -1.1),
                          const Alignment(0.6, -0.6),
                          1 - t,
                        )!,
                        size: 0.68,
                        color: AppColors.blob4,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }

  Widget _blob({
    required Alignment alignment,
    required double size,
    required Color color,
  }) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: size,
        heightFactor: size * 0.65,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
