import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/home/controllers/nearby_venues/nearby_venues_bloc.dart';
import 'package:hangout/presentation/venues_hub/venues_hub_page_wrapper.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venue_card.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venues_cta_card.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venues_loading_row.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venues_section_header.dart';
import 'package:hangout/presentation/shared/widgets/mount_entrance.dart';

class NearbyVenuesMapCarousel extends StatelessWidget {
  const NearbyVenuesMapCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NearbyVenuesBloc, NearbyVenuesState>(
      builder: (context, state) {
        if (state is NearbyVenuesInitial ||
            state is NearbyVenuesEmpty ||
            state is NearbyVenuesError) {
          return const SizedBox.shrink();
        }

        final onShowAll = state is NearbyVenuesLoaded
            ? () => VenuesHubPageWrapper.push(context)
            : null;

        return MountEntrance(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NearbyVenuesSectionHeader(onShowAll: onShowAll),
                const SizedBox(height: 10),
                switch (state) {
                  NearbyVenuesLoading() => const NearbyVenuesLoadingRow(),
                  NearbyVenuesLoaded(:final items) => _LoadedRow(items: items),
                  NearbyVenuesLocationDisabled() =>
                    const NearbyVenuesLocationDisabledCard(),
                  NearbyVenuesPermissionDenied(:final canRetry) =>
                    NearbyVenuesPermissionDeniedCard(canRetry: canRetry),
                  _ => const SizedBox.shrink(),
                },
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadedRow extends StatelessWidget {
  final List<VenueSummaryResponse> items;
  const _LoadedRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: NearbyVenueCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: items.length,
        clipBehavior: Clip.hardEdge,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => NearbyVenueCard(venue: items[index]),
      ),
    );
  }
}
