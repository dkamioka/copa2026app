import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Soft, slowly-drifting color blobs behind the content — the "liquid
/// glass" backdrop from the design.
///
/// The soft look comes from radial-gradient falloff, NOT from a real
/// blur: an earlier version ran an ImageFilter.blur(σ60) over the full
/// screen on every animated frame, which re-rasterized the whole layer
/// continuously and was the single biggest source of jank (especially
/// in debug builds and on the simulator). A gradient fade reads the
/// same at a tiny fraction of the GPU cost.
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
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 30));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The drifting blobs sit under a 60px blur that re-rasterizes every
    // animated frame — respect the system Reduce Motion setting (and
    // save the GPU work) by freezing the drift when it's on.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
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
                return Stack(
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
        // Slightly oversized vs. the old solid circle: the gradient's
        // transparent tail plays the role the blur halo used to.
        widthFactor: size * 1.25,
        heightFactor: size * 0.85,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.55),
                color.withValues(alpha: 0.4),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
