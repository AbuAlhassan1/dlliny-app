import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/featured_collection_response.dart';
import 'package:hangout/domain/dto/response/trending_venue_response.dart';
import 'package:hangout/presentation/home/controllers/nearby_venues/nearby_venues_bloc.dart';
import 'package:hangout/presentation/venues_hub/widgets/venue_poster_card.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class VenuesHubSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const VenuesHubSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PosterRail extends StatelessWidget {
  final List<Widget> children;
  const _PosterRail({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: VenuePosterCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _RailShimmer extends StatelessWidget {
  const _RailShimmer();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: VenuePosterCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, _) => Shimmer(
          duration: const Duration(milliseconds: 1200),
          color: c.onSurface,
          colorOpacity: 0.1,
          child: Container(
            width: VenuePosterCard.width,
            decoration: BoxDecoration(
              color: c.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class NearbyVenuesRail extends StatelessWidget {
  const NearbyVenuesRail({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NearbyVenuesBloc, NearbyVenuesState>(
      builder: (context, state) {
        final header = VenuesHubSectionHeader(
          title: context.pickBilingual(ar: 'قريب منك', en: 'Near you'),
          subtitle: context.pickBilingual(
            ar: 'أماكن بمنطقتك حالياً',
            en: 'Places around you right now',
          ),
        );
        return switch (state) {
          NearbyVenuesLoading() || NearbyVenuesInitial() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 12),
                const _RailShimmer(),
                const SizedBox(height: 24),
              ],
            ),
          NearbyVenuesLoaded(:final items) when items.isNotEmpty => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 12.0;
                      const columns = 2;
                      final w =
                          (constraints.maxWidth - gap * (columns - 1)) / columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final v in items)
                            VenuePosterCard(
                              venueId: v.id,
                              nameAr: v.nameAr,
                              nameEn: v.nameEn,
                              coverUrl: v.coverUrl,
                              coverStreamUrl: v.coverStreamUrl,
                              logoUrl: v.logoUrl,
                              avgRating: v.avgRating,
                              totalRatings: v.totalRatings,
                              fixedWidth: w,
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class TrendingVenuesSection extends StatefulWidget {
  const TrendingVenuesSection({super.key});

  @override
  State<TrendingVenuesSection> createState() => _TrendingVenuesSectionState();
}

class _TrendingVenuesSectionState extends State<TrendingVenuesSection> {
  final ApiService _api = serviceLocator.get<ApiService>();
  List<TrendingVenueResponse>? _items;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.getTrendingVenues(limit: 15);
      if (!mounted) return;
      setState(() {
        if (res.success && res.data != null) {
          _items = res.data!;
        } else {
          _failed = true;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (_failed) return const SizedBox.shrink();

    final header = VenuesHubSectionHeader(
      title: context.pickBilingual(ar: 'الأكثر رواجاً', en: 'Trending'),
      subtitle: context.pickBilingual(
        ar: 'الأماكن التي يتحدث عنها الناس هذا الأسبوع',
        en: 'What people are into this week',
      ),
    );

    if (items == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          const _RailShimmer(),
          const SizedBox(height: 24),
        ],
      );
    }
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 12),
        _PosterRail(
          children: [
            for (final v in items)
              VenuePosterCard(
                venueId: v.venueId,
                nameAr: v.nameAr,
                nameEn: v.nameEn,
                coverUrl: v.coverUrl,
                coverStreamUrl: v.coverStreamUrl,
                logoUrl: v.logoUrl,
                avgRating: v.avgRating,
                totalRatings: v.totalRatings,
              ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class FeaturedCollectionsSection extends StatefulWidget {
  const FeaturedCollectionsSection({super.key});

  @override
  State<FeaturedCollectionsSection> createState() =>
      _FeaturedCollectionsSectionState();
}

class _FeaturedCollectionsSectionState
    extends State<FeaturedCollectionsSection> {
  final ApiService _api = serviceLocator.get<ApiService>();
  List<FeaturedCollectionResponse>? _collections;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.getFeaturedCollections();
      if (!mounted) return;
      setState(() {
        if (res.success && res.data != null) {
          _collections =
              res.data!.where((c) => c.venues.isNotEmpty).toList();
        } else {
          _failed = true;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    final collections = _collections;

    if (collections == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VenuesHubSectionHeader(
            title: context.pickBilingual(
              ar: 'مجموعات مختارة',
              en: 'Featured collections',
            ),
          ),
          const SizedBox(height: 12),
          const _RailShimmer(),
        ],
      );
    }
    if (collections.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final col in collections) ...[
          VenuesHubSectionHeader(
            title: [
              if (col.themeEmoji != null && col.themeEmoji!.isNotEmpty)
                col.themeEmoji!,
              context.pickBilingual(ar: col.titleAr, en: col.titleEn),
            ].join('  '),
          ),
          const SizedBox(height: 12),
          _PosterRail(
            children: [
              for (final v in col.venues)
                VenuePosterCard(
                  venueId: v.venueId,
                  nameAr: v.nameAr,
                  nameEn: v.nameEn,
                  coverUrl: v.coverUrl,
                  coverStreamUrl: v.coverStreamUrl,
                  logoUrl: v.logoUrl,
                  avgRating: v.avgRating,
                  totalRatings: v.totalRatings,
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
