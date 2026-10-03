import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/hub/widgets/weekly_venues/weekly_venue_card.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class WeeklyVenuesLoadingRow extends StatelessWidget {
  const WeeklyVenuesLoadingRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WeeklyVenueCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: 3,
        clipBehavior: Clip.none,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, _) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: WeeklyVenueCard.width,
        child: Shimmer(
          duration: const Duration(milliseconds: 1400),
          color: c.onSurface.withValues(alpha: 0.06),
          colorOpacity: 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
