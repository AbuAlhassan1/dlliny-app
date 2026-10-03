import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/presentation/base/controller/tabs_bloc.dart';
import 'package:hangout/presentation/base/custom_bottom_navigation_bar.dart';
import 'package:hangout/presentation/chat/screens/chat_inbox_page_wrapper.dart';
import 'package:hangout/presentation/discover/discover_page_wrapper.dart';
import 'package:hangout/presentation/explore/controller/explore_bloc.dart';
import 'package:hangout/presentation/explore/explore_page_wrapper.dart';
import 'package:hangout/presentation/home/controllers/nearby_venues/nearby_venues_bloc.dart';
import 'package:hangout/presentation/map/map_page_wrapper.dart';
import 'package:hangout/presentation/hub/hub_page_wrapper.dart';
import 'package:hangout/presentation/my_profile/my_profile_page_wrapper.dart';
import 'package:hangout/presentation/hangout/quick_create/quick_hangout_sheet.dart';
import 'package:hangout/presentation/hangout/quick_create/quick_sheet_controller.dart';
import 'package:hangout/presentation/shared/widgets/scroll_snapy_physics.dart';

const int _reelsTabIndex = 4;

class BasePageWrapper extends StatefulWidget {
  const BasePageWrapper({super.key});

  @override
  State<BasePageWrapper> createState() => _BasePageWrapperState();
}

class _BasePageWrapperState extends State<BasePageWrapper>
    with TickerProviderStateMixin {

  late final AnimationController _quickSheetAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 0,
  );
  late final QuickSheetController _quickSheet =
      QuickSheetController(_quickSheetAnim);
  Timer? _autoExpandTimer;

  @override
  void initState() {
    context.read<TabsBloc>().setTabController(
      TabController(length: 6, vsync: this, initialIndex: 1)
      ..addListener(() {
        context.read<TabsBloc>().add(TabControllerListener());
      })
    );
    _autoExpandTimer = Timer(const Duration(milliseconds: 1300), () {
      if (mounted) _quickSheet.open();
    });
    super.initState();
  }

  @override
  void dispose() {
    _autoExpandTimer?.cancel();
    _quickSheetAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ExploreBloc>(create: (_) => ExploreBloc()),
        BlocProvider<NearbyVenuesBloc>(
          create: (_) => NearbyVenuesBloc()..add(LoadNearbyVenues()),
        ),
      ],
      child: BlocBuilder<TabsBloc, TabsState>(
        builder: (context, _) {
          final tabs = context.read<TabsBloc>();
          final reelsActive =
              tabs.tabController.index == _reelsTabIndex;
          return Theme(
            data: reelsActive ? Themes.darkTheme : Theme.of(context),
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: TabBarView(
                      controller: tabs.tabController,
                      physics: const SnappyPageScrollPhysics(),
                      children: [
                        const MyProfilePageWrapper(),
                        const HubPageWrapper(),
                        ChatInboxPageWrapper(),
                        MapPageWrapper(),
                        ExplorePageWrapper(),
                        const DiscoverPageWrapper(),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: CustomBottomNavigationBar(quickSheet: _quickSheet),
                  ),
                  Positioned.fill(
                    child: QuickHangoutSheet(controller: _quickSheet),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}