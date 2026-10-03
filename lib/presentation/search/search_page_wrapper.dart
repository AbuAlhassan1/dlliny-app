import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';
import 'package:hangout/presentation/search/controllers/search_bloc.dart';
import 'package:hangout/presentation/search/widgets/search_text_field.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';

class SearchPageWrapper extends StatelessWidget {
  const SearchPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocProvider(
      create: (_) => SearchBloc(),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: c.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                shadowColor: Colors.transparent,
                backgroundColor: c.background,
                foregroundColor: c.onSurface,
                surfaceTintColor: c.background,
                automaticallyImplyLeading: true,
                iconTheme: IconThemeData(color: c.onSurface),
                title: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Expanded(child: SearchTextField()),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  return switch (state) {
                    SearchInitial() => const SliverToBoxAdapter(
                      child: SizedBox.shrink(),
                    ),
                    SearchLoading() => SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: c.onSurface,
                          strokeWidth: 1.5,
                        ),
                      ),
                    ),
                    SearchError(:final message) => SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.onSurfaceSecondary),
                          ),
                        ),
                      ),
                    ),
                    SearchLoaded(:final response) => _ResultsSliver(
                      data: response.data!,
                    ),
                  };
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsSliver extends StatelessWidget {
  final SearchResultResponse data;
  const _ResultsSliver({required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final userCount = data.users.length;
    final venueCount = data.venues.length;
    final totalCount = userCount + venueCount;
    if (totalCount == 0) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'لا توجد نتائج',
            style: TextStyle(color: c.onSurfaceSecondary),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: totalCount,
        (context, index) => index < userCount
            ? _UserTile(user: data.users[index])
            : _VenueTile(venue: data.venues[index - userCount]),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserSearchResultDto user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfilePageWrapper(username: user.username),
        ),
      ),
      leading: CircleAvatar(
        backgroundColor: c.surfaceMuted,
        backgroundImage:
            user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
        child: user.avatarUrl == null
            ? Icon(Icons.person, color: c.onSurfaceSecondary)
            : null,
      ),
      title: Text(
        user.displayName ?? user.username,
        style: TextStyle(color: c.onSurface),
      ),
      subtitle: Text(
        '@${user.username}',
        style: TextStyle(color: c.onSurfaceSecondary),
      ),
      trailing: user.verified
          ? Icon(Icons.verified, color: c.success, size: 18)
          : null,
    );
  }
}

class _VenueTile extends StatelessWidget {
  final VenueSearchResultDto venue;
  const _VenueTile({required this.venue});

  String? _location() {
    final loc = venue.location;
    final district = loc?.districtNameAr ?? venue.district;
    final city = loc?.cityNameAr ?? venue.city;
    if (district != null && city != null) return '$district · $city';
    return district ?? city;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final location = _location();
    final hasLocation = location != null && location.isNotEmpty;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VenuePageWrapper(venueId: venue.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _Logo(url: venue.logoUrl),
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
                          venue.nameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (venue.verified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified, color: c.success, size: 14),
                      ],
                    ],
                  ),
                  Text(
                    venue.nameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (venue.onlineOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.world,
                            color: c.primary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'متجر إلكتروني',
                            style: TextStyle(
                              color: c.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (hasLocation)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            TablerIcons.map_pin,
                            color: c.onSurfaceSecondary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? url;
  const _Logo({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fallback = Icon(
      TablerIcons.building_store,
      color: c.onSurfaceSecondary,
      size: 20,
    );
    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: c.surfaceMuted,
        border: Border.all(color: c.border),
      ),
      child: url != null && url!.isNotEmpty
          ? ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: 120,
                errorWidget: (_, _, _) => Center(child: fallback),
              ),
          )
          : Center(child: fallback),
    );
  }
}
