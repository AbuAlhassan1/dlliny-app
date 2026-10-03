import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/business/campaigns/venue_campaigns_page_wrapper.dart';
import 'package:hangout/presentation/business/transfers/create_business_transfer_page_wrapper.dart';
import 'package:hangout/presentation/venue/edit_handle_page_wrapper.dart';
import 'package:hangout/presentation/venue/edit_venue_page_wrapper.dart';
import 'package:hangout/presentation/venue/manage_venue_announcements_page_wrapper.dart';
import 'package:hangout/presentation/venue/manage_venue_staff_page_wrapper.dart';
import 'package:hangout/presentation/venue/pages/venue_gallery_manager_page.dart';
import 'package:hangout/presentation/venue/pages/venue_hours_editor_page.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:hangout/presentation/venue/venue_branches_page_wrapper.dart';
import 'package:hangout/presentation/venue/venue_verification_page_wrapper.dart';

class ManageVenuePageWrapper extends StatelessWidget {
  final VenueResponse venue;
  const ManageVenuePageWrapper({super.key, required this.venue});

  static Future<void> push(BuildContext context, VenueResponse venue) {
    final venueBloc = context.read<VenueBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: venueBloc,
          child: ManageVenuePageWrapper(venue: venue),
        ),
      ),
    );
  }

  Future<void> _openHoursEditor(BuildContext context) async {
    final venueBloc = context.read<VenueBloc>();
    final saved = await VenueHoursEditorPage.push(context, venue.id);
    if (saved == true && !venueBloc.isClosed) {
      venueBloc.add(GetVenueDetails(venue.id));
    }
  }

  Future<void> _openGalleryManager(BuildContext context) async {
    final venueBloc = context.read<VenueBloc>();
    final changed = await VenueGalleryManagerPage.push(
      context,
      venue.id,
      branches: venue.locations,
    );
    if (changed == true && !venueBloc.isClosed) {
      venueBloc.add(GetVenueDetails(venue.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tiles = <_TileSpec>[
      _TileSpec(
        icon: TablerIcons.settings,
        title: LocaleKeys.manage_venue_tile_info_title.tr(),
        subtitle: LocaleKeys.manage_venue_tile_info_subtitle.tr(),
        onTap: () => EditVenuePageWrapper.push(context, venue),
      ),
      if (userHasOnVenue(context, VenuePerm.update, venue.id))
        _TileSpec(
          icon: TablerIcons.at,
          title: LocaleKeys.manage_venue_tile_handle_title.tr(),
          subtitle: LocaleKeys.manage_venue_tile_handle_subtitle.tr(),
          onTap: () => EditHandlePageWrapper.push(
            context,
            venueId: venue.id,
            currentHandle: venue.handle,
          ),
        ),
      if (userHasOnVenue(context, VenuePerm.hoursManage, venue.id))
        _TileSpec(
          icon: TablerIcons.clock,
          title: LocaleKeys.manage_venue_tile_hours_title.tr(),
          subtitle: LocaleKeys.manage_venue_tile_hours_subtitle.tr(),
          onTap: () => _openHoursEditor(context),
        ),
      if (userHasOnVenue(context, VenuePerm.mediaUpload, venue.id))
        _TileSpec(
          icon: TablerIcons.photo,
          title: LocaleKeys.manage_venue_tile_gallery_title.tr(),
          subtitle: LocaleKeys.manage_venue_tile_gallery_subtitle.tr(),
          onTap: () => _openGalleryManager(context),
        ),
      if (userHasOnVenue(context, VenuePerm.staffManage, venue.id))
        _TileSpec(
          icon: TablerIcons.users,
          title: LocaleKeys.manage_venue_tile_staff_title.tr(),
          subtitle: LocaleKeys.manage_venue_tile_staff_subtitle.tr(),
          onTap: () =>
              ManageVenueStaffPageWrapper.push(context, venue.id),
        ),
      if (!venue.onlineOnly)
        _TileSpec(
          icon: TablerIcons.building_store,
          title: LocaleKeys.manage_venue_tile_branches_title.tr(),
          subtitle: LocaleKeys.manage_venue_tile_branches_subtitle.tr(),
          onTap: () =>
              VenueBranchesPageWrapper.push(context, venue.id),
        ),
      if (userHasOnVenue(context, VenuePerm.announcementsManage, venue.id))
        _TileSpec(
          icon: TablerIcons.speakerphone,
          title: LocaleKeys.manage_venue_tile_announcements_title.tr(),
          subtitle: LocaleKeys.manage_venue_tile_announcements_subtitle.tr(),
          onTap: () =>
              ManageVenueAnnouncementsPageWrapper.push(context, venue.id),
        ),
      if (userHasOnVenue(context, VenuePerm.campaignsRead, venue.id))
        _TileSpec(
          icon: TablerIcons.ad,
          title: LocaleKeys.manage_venue_tile_campaigns_title.tr(),
          subtitle: LocaleKeys.manage_venue_tile_campaigns_subtitle.tr(),
          onTap: () => VenueCampaignsPageWrapper.push(context, venue),
        ),
      _TileSpec(
        icon: venue.verified
            ? TablerIcons.rosette_discount_check_filled
            : TablerIcons.rosette_discount_check,
        iconColor: venue.verified ? c.success : null,
        title: (venue.verified
                ? LocaleKeys.manage_venue_tile_verified_title
                : LocaleKeys.manage_venue_tile_unverified_title)
            .tr(),
        subtitle: (venue.verified
                ? LocaleKeys.manage_venue_tile_verified_subtitle
                : LocaleKeys.manage_venue_tile_unverified_subtitle)
            .tr(),
        onTap: () => VenueVerificationPageWrapper.push(
          context,
          venueId: venue.id,
          venueName: venue.nameAr,
          alreadyVerified: venue.verified,
        ),
      ),
      if (userHasOnVenue(context, VenuePerm.staffManage, venue.id))
        _TileSpec(
          icon: TablerIcons.transfer,
          iconColor: c.danger,
          title: LocaleKeys.manage_venue_tile_transfer_title.tr(),
          subtitle: LocaleKeys.manage_venue_tile_transfer_subtitle.tr(),
          onTap: () => CreateBusinessTransferPageWrapper.pushForVenue(
            context,
            venueId: venue.id,
            venueLabel: venue.nameAr,
          ),
        ),
    ];
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(
          LocaleKeys.manage_venue_page_title.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: tiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) => _ManageGridTile(spec: tiles[i]),
      ),
    );
  }
}

class _TileSpec {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _TileSpec({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _ManageGridTile extends StatelessWidget {
  final _TileSpec spec;
  const _ManageGridTile({required this.spec});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: spec.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      spec.icon,
                      color: spec.iconColor ?? c.onSurface,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      spec.title,
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                spec.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
