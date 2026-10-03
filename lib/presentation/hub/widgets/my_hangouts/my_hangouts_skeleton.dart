import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class MyHangoutsSkeleton extends StatelessWidget {
  const MyHangoutsSkeleton({super.key});

  static const double _gap = 10;
  static const double _sidePadding = 15;
  static const List<double> _leftAspects = [0.8, 1.25, 0.72];
  static const List<double> _rightAspects = [1.15, 0.7, 0.95];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _SkeletonColumn(aspects: _leftAspects)),
          const SizedBox(width: _gap),
          Expanded(child: _SkeletonColumn(aspects: _rightAspects)),
        ],
      ),
    );
  }
}

class _SkeletonColumn extends StatelessWidget {
  final List<double> aspects;
  const _SkeletonColumn({required this.aspects});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ar in aspects)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SkeletonTile(aspectRatio: ar),
          ),
      ],
    );
  }
}

class _SkeletonTile extends StatelessWidget {
  final double aspectRatio;
  const _SkeletonTile({required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Shimmer(
          duration: const Duration(milliseconds: 1400),
          color: c.onSurface,
          colorOpacity: 0.05,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface.withAlpha(50),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
