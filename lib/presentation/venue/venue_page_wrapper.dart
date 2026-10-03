import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart' hide Title;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/post/widgets/hangout_here_button.dart';
import 'package:hangout/presentation/venue/widgets/background_video_player.dart';
import 'package:hangout/presentation/venue/widgets/venue_cover_backdrop.dart';
import 'package:hangout/presentation/venue/controllers/services_controller/services_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_hours/venue_hours_bloc.dart';
import 'package:hangout/presentation/venue/widgets/services_grid.dart';
import 'package:hangout/presentation/venue/widgets/venue_action_buttons.dart';
import 'package:hangout/presentation/venue/widgets/venue_community_feed.dart';
import 'package:hangout/presentation/venue/widgets/venue_posts_grid.dart';
import 'package:hangout/presentation/venue/widgets/venue_reviews_tab.dart';
import 'package:hangout/presentation/venue/widgets/venue_avatar.dart';
import 'package:hangout/presentation/venue/widgets/venue_tab_bar.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class VenuePageWrapper extends StatefulWidget {
  final String venueId;
  const VenuePageWrapper({super.key, required this.venueId});

  @override
  State<VenuePageWrapper> createState() => _VenuePageWrapperState();
}

class _VenuePageWrapperState extends State<VenuePageWrapper> {
  final ScrollController scrollController = ScrollController();
  final PageController pageController = PageController();
  int pageIndex = 0;

  void switchPage(int index) {
    if (index == pageIndex) return;
    setState(() => pageIndex = index);
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    return MultiBlocProvider(
      providers: [
        BlocProvider<VenueBloc>(
          create: (context) =>
              VenueBloc()..add(GetVenueDetails(widget.venueId)),
        ),
        BlocProvider<ServicesBloc>(create: (context) => ServicesBloc()),
        BlocProvider<VenueHoursBloc>(
          create: (context) => VenueHoursBloc(venueId: widget.venueId),
        ),
      ],
      child: BlocListener<VenueBloc, VenueState>(
        listenWhen: (_, state) => state is GetVenueDetailsLoaded,
        listener: (context, state) {
          final hours = (state as GetVenueDetailsLoaded).venue.openingHours;
          if (hours != null) {
            context.read<VenueHoursBloc>().add(VenueHoursSeeded(hours));
          }
        },
        child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          floatingActionButton: Row(
            mainAxisAlignment: .end,
            children: [
              Column(
                mainAxisAlignment: .end,
                children: [HangoutHereButton(venueId: widget.venueId)],
              ),
            ],
          ),
          backgroundColor: t.background,
          body: NestedScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              BlocBuilder<VenueBloc, VenueState>(
                builder: (context, state) {
                  return SliverAppBar(
                    iconTheme: const IconThemeData(color: Colors.white),
                    expandedHeight:
                        MediaQuery.of(context).size.width * (14 / 9),
                    backgroundColor: t.background,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: t.background,
                    pinned: false,
                    centerTitle: false,
                    automaticallyImplyLeading: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (state is GetVenueDetailsLoaded)
                            Positioned.fill(
                              child: VenueCoverBackdrop(
                                coverUrl: state.venue.coverUrl,
                                coverMediaType: state.venue.coverMediaType,
                                coverThumbnailUrl:
                                    state.venue.coverThumbnailUrl,
                              ),
                            ),
                          SafeArea(
                            bottom: false,
                            child: Container(
                              margin: const EdgeInsets.only(top: 10, left: 15, right: 15),
                              clipBehavior: Clip.hardEdge,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: Stack(
                                  children: [
                                    if (state is GetVenueDetailsLoading ||
                                        state is VenueInitial)
                                      Shimmer(
                                        color: t.onMediaSurface,
                                        colorOpacity: 0.1,
                                        child: Container(
                                          color: t.mediaSurface.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      )
                                    else if (state is GetVenueDetailsLoaded &&
                                        state.venue.coverMediaType == 'video')
                                      BackgroundVideoPlayer(
                                        path: state.venue.coverUrl ?? "",
                                        streamUrl: state.venue.coverStreamUrl,
                                        posterUrl:
                                            state.venue.coverThumbnailUrl,
                                        venueId: widget.venueId,
                                        viewerRole: state.venue.viewerRole,
                                      )
                                    else if (state is GetVenueDetailsLoaded &&
                                        (state.venue.coverUrl?.isNotEmpty ??
                                            false))
                                      Positioned.fill(
                                        child: CachedNetworkImage(
                                          imageUrl: state.venue.coverUrl!,
                                          fit: BoxFit.cover,
                                          memCacheWidth:
                                              ((MediaQuery.of(
                                                            context,
                                                          ).size.width -
                                                          30) *
                                                      MediaQuery.of(
                                                        context,
                                                      ).devicePixelRatio)
                                                  .round(),
                                          placeholder: (_, _) =>
                                              ColoredBox(color: t.mediaSurface),
                                          errorWidget: (_, _, _) =>
                                              ColoredBox(color: t.mediaSurface),
                                        ),
                                      )
                                    else
                                      BackgroundVideoPlayer(
                                        path: "",
                                        venueId: widget.venueId,
                                        viewerRole:
                                            state is GetVenueDetailsLoaded
                                            ? state.venue.viewerRole
                                            : null,
                                      ),

                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
                                        child: Builder(
                                          builder: (context) {
                                            if (state is GetVenueDetailsError) {
                                              return _VenueLoadError(
                                                onRetry: () => context
                                                    .read<VenueBloc>()
                                                    .add(
                                                      GetVenueDetails(
                                                        widget.venueId,
                                                      ),
                                                    ),
                                              );
                                            }
                                            if (state
                                                    is GetVenueDetailsLoading ||
                                                state is VenueInitial) {
                                              return SizedBox();
                                            }

                                            final VenueResponse venue =
                                                (state as GetVenueDetailsLoaded)
                                                    .venue;
                                            return Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: .start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: .start,
                                                  children: [
                                                    VenueAvatar(
                                                      logoUrl: venue.logoUrl,
                                                      venueId: venue.id,
                                                    ),
                                                    SizedBox(width: 15),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            .start,
                                                        children: [
                                                          Row(
                                                            crossAxisAlignment:
                                                                .baseline,
                                                            textBaseline:
                                                                TextBaseline
                                                                    .alphabetic,
                                                            children: [
                                                              Flexible(
                                                                child: Shimmer(
                                                                  enabled:
                                                                      state
                                                                          is GetVenueDetailsLoading ||
                                                                      state
                                                                          is VenueInitial,
                                                                  child: Text(
                                                                    (state)
                                                                        .venue
                                                                        .nameEn,
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style: TextStyle(
                                                                      color: t
                                                                          .onMediaSurface,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w900,
                                                                      fontSize:
                                                                          30,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              _VenueRating(
                                                                avgRating: venue
                                                                    .avgRating,
                                                              ),
                                                            ],
                                                          ),
                                                          SelectableText(
                                                            "@${state.venue.handle}",
                                                            style: TextStyle(
                                                              color: t
                                                                  .onMediaSurface,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 14,
                                                              fontFamily:
                                                                  "IBMPlexSansArabic",
                                                            ),
                                                          ),
                                                          state.venue.descriptionAr !=
                                                                  null
                                                              ? Padding(
                                                                  padding:
                                                                      const EdgeInsets.only(
                                                                        top: 10,
                                                                      ),
                                                                  child: Shimmer(
                                                                    enabled:
                                                                        state
                                                                            is GetVenueDetailsLoading ||
                                                                        state
                                                                            is VenueInitial,
                                                                    child: ExpandableText(
                                                                      state
                                                                          .venue
                                                                          .descriptionAr
                                                                          .toString(),
                                                                      expandText: LocaleKeys
                                                                          .common_show_more
                                                                          .tr(),
                                                                      collapseText: LocaleKeys
                                                                          .common_show_less
                                                                          .tr(),
                                                                      style: TextStyle(
                                                                        color: t
                                                                            .onMediaSurface,
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontSize:
                                                                            12,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )
                                                              : const SizedBox(),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                SizedBox(height: 10),

                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () {},
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              venue
                                                                  .followerCount
                                                                  .toString(),
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: t
                                                                    .onMediaSurface,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 5,
                                                            ),
                                                            Text(
                                                              LocaleKeys
                                                                  .venue_stats_followers
                                                                  .tr(),
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                color: t
                                                                    .onMediaSurface,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            venue.postsCount
                                                                .toString(),
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: t
                                                                  .onMediaSurface,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            LocaleKeys
                                                                .venue_stats_posts
                                                                .tr(),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: t
                                                                  .onMediaSurface,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            venue.hangoutsCount
                                                                .toString(),
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: t
                                                                  .onMediaSurface,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            LocaleKeys
                                                                .venue_stats_hangouts
                                                                .tr(),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: t
                                                                  .onMediaSurface,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .normal,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                VenueActionButtons(
                                                  venue: venue,
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 5)),
              VenueTabBar(onTabSelected: switchPage, pageIndex: pageIndex),
              const SliverToBoxAdapter(child: SizedBox(height: 5)),
            ],

            body: BlocListener<VenueBloc, VenueState>(
              listener: (context, state) {
                if (state is GetVenueDetailsLoaded) {
                  context.read<ServicesBloc>().add(GetServices(state.venue.id));
                }
              },
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        VenueReviewsTab(venueId: widget.venueId),
                        VenuePostsGrid(venueId: widget.venueId),
                        ServicesGrid(),
                        VenueCommunityFeed(venueId: widget.venueId),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

class _VenueLoadError extends StatelessWidget {
  final VoidCallback onRetry;
  const _VenueLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(TablerIcons.alert_circle, color: t.onMediaSurface, size: 28),
        const SizedBox(height: 8),
        Text(
          LocaleKeys.common_error_generic.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: t.onMediaSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: Icon(TablerIcons.refresh, color: t.onMediaSurface, size: 18),
          label: Text(
            LocaleKeys.common_retry.tr(),
            style: TextStyle(
              color: t.onMediaSurface,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: t.onMediaSurface.withValues(alpha: 0.6)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _VenueRating extends StatelessWidget {
  final double avgRating;
  const _VenueRating({required this.avgRating});

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          TablerIcons.star_filled,
          color: Color(0xFFFFB000),
          size: 18,
        ),
        const SizedBox(width: 4),
        Text(
          avgRating.toStringAsFixed(1),
          style: TextStyle(
            color: t.onMediaSurface,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
