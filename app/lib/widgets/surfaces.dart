import 'dart:ui';

import 'package:flutter/material.dart';

/// A true frosted-glass surface (real backdrop blur). Reserved for
/// hero, one-off chrome — the segmented tab bar, the live-match
/// banner, the match-detail sheet — where the cost of a blur pass is
/// negligible because there's only ever one on screen at a time.
///
/// Repeated list items (bracket cards, group rows, scorer rows) use
/// [SoftCard] instead: real backdrop blur under dozens of concurrently
/// visible cards is a common cause of jank on-device, and the aurora
/// background is already blurred once behind everything, so a plain
/// translucent fill reads as "glass" without the extra GPU cost.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.opacity = 0.66,
    this.blurSigma = 22,
    this.padding,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double opacity;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E1E46).withValues(alpha: 0.1),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A cheap "glass-like" card: translucent white fill, soft border and
/// shadow, no per-widget blur. See [GlassSurface] for why.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.opacity = 0.82,
    this.padding,
    this.margin,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double opacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1E46).withValues(alpha: 0.09),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
