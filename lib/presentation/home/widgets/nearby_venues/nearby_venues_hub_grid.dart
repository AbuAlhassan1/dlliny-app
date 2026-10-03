import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/presentation/home/controllers/nearby_venues/nearby_venues_bloc.dart';
import 'package:hangout/presentation/venues_hub/venues_hub_page_wrapper.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venues_cta_card.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venues_loading_row.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venues_promo_card.dart';
import 'package:hangout/presentation/home/widgets/nearby_venues/nearby_venues_section_header.dart';
import 'package:hangout/presentation/shared/widgets/mount_entrance.dart';

class NearbyVenuesHubGrid extends StatelessWidget {
  const NearbyVenuesHubGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NearbyVenuesBloc, NearbyVenuesState>(
      builder: (context, state) {
        if (state is NearbyVenuesInitial ||
            state is NearbyVenuesEmpty ||
            state is NearbyVenuesError) {
          return const SizedBox.shrink();
        }

        if (state is NearbyVenuesLoaded) {
          return MountEntrance(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: NearbyVenuesPromoCard(
                venues: state.items,
                onTap: () => VenuesHubPageWrapper.push(context),
              ),
            ),
          );
        }

        return MountEntrance(
          child: Container(
            padding: const EdgeInsets.only(bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NearbyVenuesSectionHeader(onShowAll: null),
                const SizedBox(height: 10),
                switch (state) {
                  NearbyVenuesLoading() => const NearbyVenuesLoadingRow(),
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

