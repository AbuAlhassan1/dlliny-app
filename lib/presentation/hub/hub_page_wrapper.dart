import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/app_page_gradient.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/base/controller/tabs_bloc.dart';
import 'package:hangout/presentation/home/controllers/awaiting_review/awaiting_review_bloc.dart';
import 'package:hangout/presentation/home/controllers/nearby_venues/nearby_venues_bloc.dart';
import 'package:hangout/presentation/home/controllers/recent_attended/recent_attended_bloc.dart';
import 'package:hangout/presentation/memory/bloc/memory_tray/memory_tray_bloc.dart';
import 'package:hangout/presentation/home/widgets/awaiting_review_card.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venues_hub_grid.dart';
import 'package:hangout/presentation/home/controllers/people_nearby/people_nearby_bloc.dart';
import 'package:hangout/presentation/home/widgets/people_nearby_carousel.dart';
import 'package:hangout/presentation/hub/controllers/intents/intents_bloc.dart';
import 'package:hangout/presentation/hub/controllers/my_hangouts/my_hub_hangouts_bloc.dart';
import 'package:hangout/presentation/hub/controllers/my_invitations/my_invitations_bloc.dart';
import 'package:hangout/presentation/hub/controllers/my_upcoming_hangouts/my_upcoming_hangouts_bloc.dart';
import 'package:hangout/presentation/hub/controllers/weekly_venues/weekly_venues_bloc.dart';
import 'package:hangout/presentation/hub/widgets/intents_section.dart';
import 'package:hangout/presentation/hub/widgets/my_hangouts_section.dart';
import 'package:hangout/presentation/challenges/controllers/challenges_list/challenges_list_bloc.dart';
import 'package:hangout/presentation/events/controllers/public_events_bloc.dart';
import 'package:hangout/presentation/events/widgets/public_events_section.dart';
import 'package:hangout/presentation/hub/widgets/challenges_island.dart';
import 'package:hangout/presentation/hub/widgets/hangout_invitations_section.dart';
import 'package:hangout/presentation/hub/widgets/my_upcoming_hangouts_section.dart';
import 'package:hangout/presentation/hub/widgets/weekly_venues_section.dart';
import 'package:showcaseview/showcaseview.dart';

const int _hubTabIndex = 1;

class HubPageWrapper extends StatefulWidget {
  const HubPageWrapper({super.key});

  @override
  State<HubPageWrapper> createState() => _HubPageWrapperState();
}

class _HubPageWrapperState extends State<HubPageWrapper>
    with AutomaticKeepAliveClientMixin {
  late final AwaitingReviewBloc _awaitingReviewBloc;

  @override
  void initState() {
    super.initState();
    _awaitingReviewBloc = AwaitingReviewBloc()..add(LoadAwaitingReview());
  }

  @override
  void dispose() {
    _awaitingReviewBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider<WeeklyVenuesBloc>(
          create: (_) => WeeklyVenuesBloc()..add(LoadWeeklyVenues()),
        ),
        BlocProvider<HubIntentsBloc>(
          create: (_) => HubIntentsBloc()..add(LoadIntents()),
        ),
        BlocProvider<MyHubHangoutsBloc>(
          create: (_) => MyHubHangoutsBloc()..add(const LoadMyHubHangouts()),
        ),
        BlocProvider<MyUpcomingHangoutsBloc>(
          create: (_) =>
              MyUpcomingHangoutsBloc()..add(const LoadMyUpcomingHangouts()),
        ),
        BlocProvider<MyInvitationsBloc>(
          create: (_) => MyInvitationsBloc()..add(LoadMyInvitations()),
        ),
        BlocProvider<PublicEventsBloc>(
          create: (_) => PublicEventsBloc()..add(LoadPublicEvents()),
        ),
        BlocProvider<RecentAttendedBloc>(
          create: (_) => RecentAttendedBloc()..add(LoadRecentAttended()),
        ),

        BlocProvider<ChallengesListBloc>(
          create: (_) => ChallengesListBloc()..add(const LoadChallenges()),
        ),

        BlocProvider<PeopleNearbyBloc>(
          create: (_) => PeopleNearbyBloc()..add(LoadPeopleNearby()),
        ),
        BlocProvider<AwaitingReviewBloc>.value(value: _awaitingReviewBloc),
      ],
      child: _HubView(
        onTabSelected: () => _awaitingReviewBloc.add(LoadAwaitingReview()),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _HubView extends StatefulWidget {
  final VoidCallback onTabSelected;
  const _HubView({required this.onTabSelected});

  @override
  State<_HubView> createState() => _HubViewState();
}

class _HubViewState extends State<_HubView> {
  final GlobalKey _kWeekly = GlobalKey();
  final GlobalKey _kAwaiting = GlobalKey();
  final GlobalKey _kNearby = GlobalKey();
  final GlobalKey _kUpcoming = GlobalKey();
  final GlobalKey _kIntents = GlobalKey();
  final GlobalKey _kMyHangouts = GlobalKey();
  late final List<GlobalKey> _orderedKeys = [
    _kWeekly,
    _kAwaiting,
    _kNearby,
    _kUpcoming,
    _kIntents,
    _kMyHangouts,
  ];
  late final Map<GlobalKey, GlobalKey> _measureKeys = {
    _kWeekly: GlobalKey(),
    _kAwaiting: GlobalKey(),
    _kNearby: GlobalKey(),
    _kUpcoming: GlobalKey(),
    _kIntents: GlobalKey(),
    _kMyHangouts: GlobalKey(),
  };
  final AppCacheRepository _cache = serviceLocator.get<AppCacheRepository>();
  final ScrollController _scrollController = ScrollController();
  late final ShowcaseView _showcaseView;
  bool? _seen;
  bool _started = false;
  bool _seenPersisted = false;
  bool _fallbackFired = false;
  Timer? _fallbackTimer;
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _loadSeen();
    serviceLocator.get<MemoryTrayBloc>().add(TrayRefreshed());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_registered) return;
    _registered = true;
    final c = context.c;
    _showcaseView = ShowcaseView.register(
      enableAutoScroll: true,
      skipIfTargetNotPresent: true,
      onFinish: _markSeen,
      onDismiss: (_) => _markSeen(),
      globalTooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.inside,
        alignment: MainAxisAlignment.spaceBetween,
        actionGap: 16,
        gapBetweenContentAndAction: 12,
      ),
      globalTooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.skip,
          name: LocaleKeys.common_skip.tr(),
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          textStyle: TextStyle(
            color: c.onSurfaceSecondary,
            fontWeight: FontWeight.w600,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: LocaleKeys.common_next.tr(),
          backgroundColor: c.primary,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          textStyle: TextStyle(
            color: c.onPrimary,
            fontWeight: FontWeight.w700,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _showcaseView.unregister();
    _scrollController.dispose();
    super.dispose();
  }

  void _markSeen() {
    if (_seenPersisted) return;
    _seenPersisted = true;
    _cache.write(HubCacheKeys.showcaseSeen, true);
  }

  Future<void> _loadSeen() async {
    final v = await _cache.read(HubCacheKeys.showcaseSeen);
    if (!mounted) return;
    _seen = v == true;
    if (_seen == false) _armTour();
  }

  void _armTour() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(milliseconds: 3500), () {
      _fallbackFired = true;
      if (mounted) _maybeStart();
    });
    _maybeStart();
  }

  void _maybeStart() {
    if (!mounted || _seen != false || _started) return;
    if (!_fallbackFired && !_contentReady()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _started) return;
      final keys = _orderedKeys.where(_isVisible).toList();
      if (keys.isEmpty) return;
      _started = true;
      _fallbackTimer?.cancel();
      ShowcaseView.get().startShowCase(
        keys,
        delay: const Duration(milliseconds: 400),
      );
    });
  }

  bool _contentReady() {
    if (!mounted) return false;
    final weekly = context.read<WeeklyVenuesBloc>().state;
    final intents = context.read<HubIntentsBloc>().state;
    final awaiting = context.read<AwaitingReviewBloc>().state;
    final upcoming = context.read<MyUpcomingHangoutsBloc>().state;
    final nearby = context.read<NearbyVenuesBloc>().state;
    final mine = context.read<MyHubHangoutsBloc>().state;
    return weekly is! WeeklyVenuesInitial &&
        weekly is! WeeklyVenuesLoading &&
        intents is! HubIntentsInitial &&
        intents is! HubIntentsListLoading &&
        awaiting is! AwaitingReviewInitial &&
        awaiting is! AwaitingReviewLoading &&
        upcoming is! MyUpcomingHangoutsInitial &&
        upcoming is! MyUpcomingHangoutsLoading &&
        nearby is! NearbyVenuesInitial &&
        nearby is! NearbyVenuesLoading &&
        mine is! MyHubHangoutsInitial &&
        mine is! MyHubHangoutsLoading;
  }

  bool _isVisible(GlobalKey key) {
    final ctx = _measureKeys[key]?.currentContext;
    if (ctx == null) return false;
    final ro = ctx.findRenderObject();
    return ro is RenderBox && ro.hasSize && ro.size.height > 1;
  }

  void _onHubRetapped(BuildContext context) {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 0) {
      _onRefresh(context);
    } else {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _onRefresh(BuildContext context) async {
    context.read<WeeklyVenuesBloc>().add(LoadWeeklyVenues());
    context.read<HubIntentsBloc>().add(LoadIntents());
    context.read<NearbyVenuesBloc>().add(LoadNearbyVenues());
    context.read<RecentAttendedBloc>().add(LoadRecentAttended());
    serviceLocator.get<MemoryTrayBloc>().add(TrayRefreshed());
    context.read<AwaitingReviewBloc>().add(LoadAwaitingReview());
    context.read<MyHubHangoutsBloc>().add(const LoadMyHubHangouts());
    context.read<MyUpcomingHangoutsBloc>().add(const LoadMyUpcomingHangouts());
    context.read<MyInvitationsBloc>().add(LoadMyInvitations());
    context.read<PublicEventsBloc>().add(LoadPublicEvents());
    context.read<ChallengesListBloc>().add(const LoadChallenges());
    context.read<PeopleNearbyBloc>().add(LoadPeopleNearby());
    await context.read<WeeklyVenuesBloc>().stream.firstWhere(
      (s) =>
          s is WeeklyVenuesLoaded ||
          s is WeeklyVenuesEmpty ||
          s is WeeklyVenuesError,
    );
  }

  Widget _showcase({
    required GlobalKey key,
    required String titleKey,
    required String descKey,
    required Widget child,
  }) {
    final c = context.c;
    return Showcase(
      key: key,
      title: titleKey.tr(),
      description: descKey.tr(),
      titleTextStyle: TextStyle(
        color: c.onSurface,
        fontWeight: FontWeight.w800,
        fontSize: 15,
        fontFamily: 'IBMPlexSansArabic',
      ),
      descTextStyle: TextStyle(
        color: c.onSurfaceSecondary,
        fontSize: 13,
        height: 1.3,
        fontFamily: 'IBMPlexSansArabic',
      ),
      tooltipBackgroundColor: c.surfaceElevated,
      textColor: c.onSurface,
      targetBorderRadius: BorderRadius.circular(16),
      targetPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      overlayColor: Colors.black,
      overlayOpacity: 0.78,
      child: KeyedSubtree(key: _measureKeys[key], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final sections = <Widget>[
      const RepaintBoundary(child: HangoutInvitationsSection()),
      const RepaintBoundary(child: PublicEventsSection()),
      
      const Row(
        children: [
          Expanded(child: ChallengesIsland()),
        ],
      ),

      SizedBox(height: 15),

      RepaintBoundary(
        child: _showcase(
          key: _kNearby,
          titleKey: LocaleKeys.hub_showcase_nearby_title,
          descKey: LocaleKeys.hub_showcase_nearby_desc,
          child: const NearbyVenuesHubGrid(),
        ),
      ),

      RepaintBoundary(
        child: _showcase(
          key: _kIntents,
          titleKey: LocaleKeys.hub_showcase_intents_title,
          descKey: LocaleKeys.hub_showcase_intents_desc,
          child: const IntentsSection(),
        ),
      ),

      RepaintBoundary(
        child: _showcase(
          key: _kWeekly,
          titleKey: LocaleKeys.hub_showcase_weekly_title,
          descKey: LocaleKeys.hub_showcase_weekly_desc,
          child: const WeeklyVenuesSection(),
        ),
      ),

      RepaintBoundary(
        child: _showcase(
          key: _kAwaiting,
          titleKey: LocaleKeys.hub_showcase_awaiting_title,
          descKey: LocaleKeys.hub_showcase_awaiting_desc,
          child: const AwaitingReviewCard(),
        ),
      ),

      const RepaintBoundary(child: PeopleNearbyCarousel()),

      RepaintBoundary(
        child: _showcase(
          key: _kUpcoming,
          titleKey: LocaleKeys.hub_showcase_upcoming_title,
          descKey: LocaleKeys.hub_showcase_upcoming_desc,
          child: const MyUpcomingHangoutsSection(),
        ),
      ),
      RepaintBoundary(
        child: _showcase(
          key: _kMyHangouts,
          titleKey: LocaleKeys.hub_showcase_my_hangouts_title,
          descKey: LocaleKeys.hub_showcase_my_hangouts_desc,
          child: const MyHangoutsSection(),
        ),
      ),
      const SizedBox(height: 80),
    ];

    return MultiBlocListener(
      listeners: [
        BlocListener<TabsBloc, TabsState>(
          listenWhen: (_, curr) => curr is TabSelected,
          listener: (context, _) {
            final tabs = context.read<TabsBloc>();
            if (tabs.tabController.indexIsChanging) return;
            if (tabs.tabController.index != _hubTabIndex) return;
            widget.onTabSelected();
          },
        ),
        BlocListener<TabsBloc, TabsState>(
          listenWhen: (_, curr) =>
              curr is TabRetappedState && curr.index == _hubTabIndex,
          listener: (context, _) => _onHubRetapped(context),
        ),
        BlocListener<WeeklyVenuesBloc, WeeklyVenuesState>(
          listener: (_, _) => _maybeStart(),
        ),
        BlocListener<HubIntentsBloc, HubIntentsState>(
          listener: (_, _) => _maybeStart(),
        ),
        BlocListener<AwaitingReviewBloc, AwaitingReviewState>(
          listener: (_, _) => _maybeStart(),
        ),
        BlocListener<MyUpcomingHangoutsBloc, MyUpcomingHangoutsState>(
          listener: (_, _) => _maybeStart(),
        ),
        BlocListener<NearbyVenuesBloc, NearbyVenuesState>(
          listener: (_, _) => _maybeStart(),
        ),
        BlocListener<MyHubHangoutsBloc, MyHubHangoutsState>(
          listener: (_, _) => _maybeStart(),
        ),
      ],
      child: Scaffold(
        backgroundColor: c.background,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: appPageGradient(context)),
          child: SafeArea(
            top: false,
            child: RefreshIndicator(
              color: c.onSurface,
              backgroundColor: c.background,
              displacement: 160,
              onRefresh: () => _onRefresh(context),
              child: SafeArea(
                child: ListView.builder(
                  scrollCacheExtent: ScrollCacheExtent.pixels(600), controller: _scrollController,
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: sections.length,
                  itemBuilder: (context, index) => sections[index],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
