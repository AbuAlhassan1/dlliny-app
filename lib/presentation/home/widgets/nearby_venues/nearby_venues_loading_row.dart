import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venue_card.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class NearbyVenuesLoadingRow extends StatelessWidget {
  const NearbyVenuesLoadingRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: NearbyVenueCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, _) => ClipRRect(
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.hardEdge,
          child: Shimmer(
            duration: const Duration(milliseconds: 1200),
            color: c.onSurface,
            colorOpacity: 0.1,
            child: Container(
              width: NearbyVenueCard.width,
              decoration: BoxDecoration(
                color: c.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
