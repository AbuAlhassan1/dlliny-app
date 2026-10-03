import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/home/widgets/recent_attended/recent_attended_card.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class RecentAttendedLoadingRow extends StatelessWidget {
  const RecentAttendedLoadingRow({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RecentAttendedCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: 3,
        clipBehavior: Clip.none,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
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
    return SizedBox(
      width: RecentAttendedCard.width,
      child: Shimmer(
        duration: const Duration(milliseconds: 1400),
        color: c.onSurface.withValues(alpha: 0.06),
        colorOpacity: 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
