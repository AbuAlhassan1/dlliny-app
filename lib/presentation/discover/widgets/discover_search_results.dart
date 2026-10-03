import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/domain/dto/response/trending_venue_response.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';

class DiscoverSearchResults extends StatelessWidget {
  final String query;
  final bool loading;
  final SearchResultResponse? results;
  final List<TrendingVenueResponse> trending;

  const DiscoverSearchResults({
    super.key,
    required this.query,
    required this.loading,
    required this.results,
    required this.trending,
  });

  bool get _hasQuery => query.trim().length >= 2;

  void _openProfile(BuildContext context, String username) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfilePageWrapper(username: username)),
    );
  }

  void _openVenue(BuildContext context, String venueId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VenuePageWrapper(venueId: venueId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    if (!_hasQuery) {
      if (trending.isEmpty) {
        return _Hint(
          icon: TablerIcons.search,
          text: context.pickBilingual(
            ar: 'ابحث عن أشخاص وأماكن',
            en: 'Search for people and places',
          ),
        );
      }
      return ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.only(top: 6, bottom: 120),
        children: [
          _SectionHeader(
            label: context.pickBilingual(ar: 'رائج الآن', en: 'Trending now'),
          ),
          for (final v in trending)
            _ResultRow(
              imageUrl: v.logoUrl,
              square: true,
              title: context.pickBilingual(ar: v.nameAr, en: v.nameEn ?? v.nameAr),
              subtitle: v.categoryCode,
              verified: false,
              onTap: () => _openVenue(context, v.venueId),
            ),
        ],
      );
    }

    if (loading && results == null) {
      return Center(
        child: CircularProgressIndicator(color: c.primary, strokeWidth: 2),
      );
    }

    final users = results?.users ?? const [];
    final venues = results?.venues ?? const [];

    if (users.isEmpty && venues.isEmpty) {
      return _Hint(
        icon: TablerIcons.mood_empty,
        text: context.pickBilingual(
          ar: 'لا توجد نتائج لـ "$query"',
          en: 'No results for "$query"',
        ),
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(top: 6, bottom: 120),
      children: [
        if (users.isNotEmpty) ...[
          _SectionHeader(
            label: context.pickBilingual(ar: 'الحسابات', en: 'Accounts'),
          ),
          for (final u in users)
            _ResultRow(
              imageUrl: u.avatarUrl,
              square: false,
              title: (u.displayName?.trim().isNotEmpty ?? false)
                  ? u.displayName!.trim()
                  : u.username,
              subtitle: '@${u.username}',
              verified: u.verified,
              onTap: () => _openProfile(context, u.username),
            ),
        ],
        if (venues.isNotEmpty) ...[
          _SectionHeader(
            label: context.pickBilingual(ar: 'الأماكن', en: 'Places'),
          ),
          for (final v in venues)
            _ResultRow(
              imageUrl: v.logoUrl,
              square: true,
              title: context.pickBilingual(ar: v.nameAr, en: v.nameEn),
              subtitle: _venueSubtitle(context, v),
              verified: v.verified,
              onTap: () => _openVenue(context, v.id),
            ),
        ],
      ],
    );
  }

  String? _venueSubtitle(BuildContext context, VenueSearchResultDto v) {
    final loc = v.location;
    final city = context.pickBilingual(
      ar: loc?.cityNameAr ?? v.city ?? '',
      en: loc?.cityNameEn ?? v.city ?? '',
    );
    final district = context.pickBilingual(
      ar: loc?.districtNameAr ?? v.district ?? '',
      en: loc?.districtNameEn ?? v.district ?? '',
    );
    final parts = [
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
    ];
    return parts.isEmpty ? v.categoryCode : parts.join(' · ');
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          color: c.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String? imageUrl;
  final bool square;
  final String title;
  final String? subtitle;
  final bool verified;
  final VoidCallback onTap;

  const _ResultRow({
    required this.imageUrl,
    required this.square,
    required this.title,
    required this.subtitle,
    required this.verified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasImg = imageUrl != null && imageUrl!.isNotEmpty;
    final radius = square ? 12.0 : 100.0;
    final fallback = Icon(
      square ? TablerIcons.building_store : TablerIcons.user,
      color: c.onSurfaceSecondary,
      size: 22,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                width: 48,
                height: 48,
                color: c.surfaceMuted,
                child: hasImg
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 144,
                        errorWidget: (_, _, _) => Center(child: fallback),
                      )
                    : Center(child: fallback),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ),
                      if (verified) ...[
                        const SizedBox(width: 4),
                        Icon(
                          TablerIcons.rosette_discount_check_filled,
                          color: c.success,
                          size: 15,
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 12.5,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.onSurfaceMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 14,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
