import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/tabs/audience_tab.dart';
import 'package:hangout/presentation/business/analytics/tabs/competition_tab.dart';
import 'package:hangout/presentation/business/analytics/tabs/content_tab.dart';
import 'package:hangout/presentation/business/analytics/tabs/funnel_tab.dart';
import 'package:hangout/presentation/business/analytics/tabs/overview_tab.dart';

class VenueAnalyticsPage extends StatelessWidget {
  final String venueId;
  final String? venueName;

  const VenueAnalyticsPage({
    super.key,
    required this.venueId,
    this.venueName,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleKeys.business_analytics_page_title.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              if (venueName != null && venueName!.isNotEmpty)
                Text(
                  venueName!,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: c.onSurface,
              labelColor: c.onSurface,
              unselectedLabelColor: c.onSurfaceSecondary,
              dividerHeight: 0,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(text: LocaleKeys.business_analytics_tab_overview.tr()),
                Tab(text: LocaleKeys.business_analytics_tab_content.tr()),
                _ProTab(label: LocaleKeys.business_analytics_tab_funnel.tr()),
                _ProTab(label: LocaleKeys.business_analytics_tab_competition.tr()),
                _ProTab(label: LocaleKeys.business_analytics_tab_audience.tr()),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            OverviewTab(venueId: venueId),
            ContentTab(venueId: venueId),
            FunnelTab(venueId: venueId),
            CompetitionTab(venueId: venueId),
            AudienceTab(venueId: venueId),
          ],
        ),
      ),
    );
  }
}

class _ProTab extends StatelessWidget {
  final String label;
  const _ProTab({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 6),
          Icon(TablerIcons.crown, size: 12, color: c.onSurfaceSecondary),
        ],
      ),
    );
  }
}
