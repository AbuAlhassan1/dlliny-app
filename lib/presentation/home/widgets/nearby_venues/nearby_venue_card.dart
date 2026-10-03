import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';

const double _logoSize = 40;

class NearbyVenueCard extends StatelessWidget {
  static const double width = 260;
  static const double height = 60;

  final VenueSummaryResponse venue;
  const NearbyVenueCard({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: width,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VenuePageWrapper(venueId: venue.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Logo(logoUrl: venue.logoUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue.nameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _LocationRow(
                        city: venue.cityNameAr,
                        district: venue.districtNameAr,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NearbyVenueBoxCard extends StatelessWidget {
  static const double _boxLogoSize = 56;

  final VenueSummaryResponse venue;
  final double width;

  const NearbyVenueBoxCard({
    super.key,
    required this.venue,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VenuePageWrapper(venueId: venue.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _BoxLogo(logoUrl: venue.logoUrl, size: _boxLogoSize),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      venue.nameAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoxLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;
  const _BoxLogo({required this.logoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.border, width: 2),
      ),
      child: (logoUrl != null && logoUrl!.isNotEmpty)
          ? ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: CachedNetworkImage(
                imageUrl: logoUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 180,
                errorWidget: (_, _, _) => Icon(
                  TablerIcons.building_store,
                  color: c.onSurfaceSecondary,
                  size: 24,
                ),
              ),
          )
          : Icon(
              TablerIcons.building_store,
              color: c.onSurfaceSecondary,
              size: 24,
            ),
    );
  }
}

class _BoxLocation extends StatelessWidget {
  final String? city;
  final String? district;
  const _BoxLocation({required this.city, required this.district});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasCity = city != null && city!.isNotEmpty;
    final hasDistrict = district != null && district!.isNotEmpty;
    if (!hasCity && !hasDistrict) return const SizedBox.shrink();
    final label = [
      if (hasCity) city!,
      if (hasDistrict) district!,
    ].join(' · ');
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          TablerIcons.map_pin,
          size: 10,
          color: c.onSurfaceSecondary,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  final String? logoUrl;
  const _Logo({required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: _logoSize,
      height: _logoSize,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.border),
      ),
      child: (logoUrl != null && logoUrl!.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: CachedNetworkImage(
                imageUrl: logoUrl!,
                fit: BoxFit.cover,
                memCacheWidth: 180,
                errorWidget: (_, _, _) => Icon(
                  TablerIcons.building_store,
                  color: c.onSurfaceSecondary,
                  size: 20,
                ),
              ),
            )
          : Icon(
              TablerIcons.building_store,
              color: c.onSurfaceSecondary,
              size: 20,
            ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String? city;
  final String? district;
  const _LocationRow({required this.city, required this.district});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasCity = city != null && city!.isNotEmpty;
    final hasDistrict = district != null && district!.isNotEmpty;
    if (!hasCity && !hasDistrict) return const SizedBox.shrink();
    final label = [
      if (hasCity) city!,
      if (hasDistrict) district!,
    ].join(' · ');
    return Row(
      children: [
        Icon(
          TablerIcons.map_pin,
          size: 11,
          color: c.onSurfaceSecondary,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _TrailingMeta extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final int followersCount;
  const _TrailingMeta({
    required this.rating,
    required this.totalRatings,
    required this.followersCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasRatings = totalRatings > 0;
    final hasFollowers = followersCount > 0;
    if (!hasRatings && !hasFollowers) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasRatings)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                TablerIcons.star_filled,
                size: 11,
                color: Color(0xFFFFB000),
              ),
              const SizedBox(width: 3),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        if (hasRatings && hasFollowers) const SizedBox(height: 2),
        if (hasFollowers)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                TablerIcons.users,
                size: 11,
                color: c.onSurfaceSecondary,
              ),
              const SizedBox(width: 3),
              Text(
                _formatFollowers(followersCount),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

String _formatFollowers(int n) {
  if (n < 1000) return n.toString();
  if (n < 1000000) {
    final k = n / 1000;
    return '${k.toStringAsFixed(k < 10 ? 1 : 0)}k';
  }
  final m = n / 1000000;
  return '${m.toStringAsFixed(m < 10 ? 1 : 0)}m';
}
