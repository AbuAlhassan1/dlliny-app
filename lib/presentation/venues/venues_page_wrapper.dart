import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/venue_analytics_page.dart';
import 'package:hangout/presentation/orders/venue_orders_inbox_page_wrapper.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';
import 'package:hangout/presentation/venues/controllers/venues_controller/venues_bloc.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_modal_bottom_sheet.dart';

class VenuesPageWrapper extends StatefulWidget {
  final BusinessAccountResponse business;
  const VenuesPageWrapper({super.key, required this.business});

  @override
  State<VenuesPageWrapper> createState() => _VenuesPageWrapperState();
}

class _VenuesPageWrapperState extends State<VenuesPageWrapper> {
  @override
  Widget build(BuildContext x) {
    final t = x.c;
    return BlocProvider(
      create: (context) =>
          VenuesBloc()
            ..add(GetVenuesByBusinessId(widget.business.id.toString())),
      child: Scaffold(
        backgroundColor: t.background,
        appBar: AppBar(
          title: Text(
            LocaleKeys.my_venues_page_title.tr(
              namedArgs: {'name': widget.business.companyName ?? ''},
            ),
            style: TextStyle(color: t.onSurface, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isDismissible: false,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) =>
                    CreateVneueModalBottomSheet(
                      businessId: widget.business.id,
                    ),
              ),
              icon: Icon(Icons.add),
            )
          ],
        ),
        body: BlocBuilder<VenuesBloc, VenuesState>(
          builder: (c, state) {
            if (state is GetVenuesLoading || state is VenuesInitial) {
              return Center(
                child: CircularProgressIndicator(
                  color: t.onSurface,
                  strokeWidth: 1,
                ),
              );
            }

            if (state is GetVenuesError) {
              return Center(child: Text(state.message));
            }

            List<BusinessVenueResponse> venues =
                (state as GetVenuesLoaded).response;

            return Builder(
              builder: (context) {
                return RefreshIndicator(
                  onRefresh: () async =>
                      Future.delayed(const Duration(seconds: 1), () {
                        c.read<VenuesBloc>().add(
                          GetVenuesByBusinessId(widget.business.id.toString()),
                        );
                      }),
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 20,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: venues.length,
                    itemBuilder: (c, index) => _VenueGridTile(
                      venue: venues[index],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _VenueGridTile extends StatelessWidget {
  final BusinessVenueResponse venue;
  const _VenueGridTile({required this.venue});

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VenuePageWrapper(venueId: venue.venueId),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: t.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  image: venue.logoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(venue.logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: venue.logoUrl == null
                    ? Icon(
                        TablerIcons.building_store,
                        color: t.onSurfaceSecondary,
                        size: 22,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              venue.nameAr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              venue.nameEn,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.onSurfaceSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                _StatusChip(
                  label: (venue.active
                          ? LocaleKeys.my_venues_status_active
                          : LocaleKeys.my_venues_status_inactive)
                      .tr(),
                  color: venue.active ? Colors.green : Colors.red,
                ),
                _StatusChip(
                  label: (venue.verified
                          ? LocaleKeys.my_venues_status_verified
                          : LocaleKeys.my_venues_status_unverified)
                      .tr(),
                  color: venue.verified ? Colors.blue : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 6),
            _ActionButton(
              label: LocaleKeys.my_venues_action_analytics.tr(),
              icon: TablerIcons.chart_bar,
              background: Colors.blue,
              foreground: t.onPrimary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VenueAnalyticsPage(
                    venueId: venue.venueId,
                    venueName: venue.nameAr,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            _ActionButton(
              label: LocaleKeys.my_venues_action_orders.tr(),
              icon: TablerIcons.shopping_bag,
              background: t.onSurface,
              foreground: t.surface,
              onTap: () => VenueOrdersInboxPageWrapper.push(
                context,
                venueId: venue.venueId,
                venueName: venue.nameAr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 7),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
