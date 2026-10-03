import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class SelectedVenueCard extends StatelessWidget {
  final String fallbackNameAr;
  final String fallbackNameEn;

  final VenueResponse? details;
  final bool loading;
  final VoidCallback onClear;

  const SelectedVenueCard({
    super.key,
    required this.fallbackNameAr,
    required this.fallbackNameEn,
    required this.details,
    required this.loading,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = details != null
        ? (details!.nameAr.isNotEmpty ? details!.nameAr : details!.nameEn)
        : (fallbackNameAr.isNotEmpty ? fallbackNameAr : fallbackNameEn);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            c.onSurface.withValues(alpha: 0.10),
            c.onSurface.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(
          color: c.border,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _VenueLogoSlot(url: details?.logoUrl, loading: loading),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (details?.verified == true) ...[
                      const SizedBox(width: 4),
                      Icon(
                        TablerIcons.discount_check_filled,
                        size: 14,
                        color: c.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                _RatingAndLocationLine(details: details),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onClear,
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: c.onSurface.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: c.onSurfaceSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VenueLogoSlot extends StatelessWidget {
  final String? url;
  final bool loading;
  const _VenueLogoSlot({required this.url, required this.loading});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const size = 52.0;
    Widget child;
    if (loading && url == null) {
      child = Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            color: c.onSurfaceSecondary,
            strokeWidth: 1.5,
          ),
        ),
      );
    } else if (url != null && url!.isNotEmpty) {
      child = CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => Icon(
          TablerIcons.building_store,
          color: c.onSurfaceSecondary,
          size: 22,
        ),
      );
    } else {
      child = Icon(
        TablerIcons.building_store,
        color: c.onSurfaceSecondary,
        size: 22,
      );
    }
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: c.onSurface.withValues(alpha: 0.06),
      ),
      child: child,
    );
  }
}

class _RatingAndLocationLine extends StatelessWidget {
  final VenueResponse? details;
  const _RatingAndLocationLine({required this.details});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final v = details;
    final hasRating = v != null && v.totalRatings > 0;
    final city = v?.cityNameAr;
    final district = v?.districtNameAr;
    final location = [
      if (city != null && city.isNotEmpty) city,
      if (district != null && district.isNotEmpty) district,
    ].join(' · ');

    if (!hasRating && location.isEmpty) {
      return Text(
        LocaleKeys.hangout_create_venue_loading.tr(),
        style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
      );
    }

    return Row(
      children: [
        if (hasRating) ...[
          _RatingChip(avgRating: v.avgRating, totalRatings: v.totalRatings),
          if (location.isNotEmpty) const SizedBox(width: 8),
        ],
        if (location.isNotEmpty)
          Flexible(
            child: Text(
              location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double avgRating;
  final int totalRatings;
  const _RatingChip({required this.avgRating, required this.totalRatings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(TablerIcons.star_filled, size: 11, color: Colors.amber),
          const SizedBox(width: 3),
          Text(
            avgRating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '($totalRatings)',
            style: TextStyle(
              color: Colors.amber.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
