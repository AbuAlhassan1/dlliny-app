import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/presentation/hub/controllers/intents/intents_bloc.dart';
import 'package:hangout/presentation/hub/widgets/intents/intent_chips_row.dart';
import 'package:hangout/presentation/hub/widgets/intents/intent_venues_list.dart';
import 'package:hangout/presentation/hub/widgets/intents/intents_section_header.dart';

class IntentsSection extends StatelessWidget {
  const IntentsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HubIntentsBloc, HubIntentsState>(
      builder: (context, state) {
        if (state is HubIntentsInitial || state is HubIntentsError) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IntentsSectionHeader(
                isRefreshing: state is HubIntentsReady && state.isRefreshing,
              ),
              const SizedBox(height: 12),
              switch (state) {
                HubIntentsListLoading() => const IntentChipsLoadingRow(),
                HubIntentsReady(:final intents, :final selectedCode) =>
                  IntentChipsRow(
                    intents: intents,
                    selectedCode: selectedCode,
                    onSelect: (code) => context
                        .read<HubIntentsBloc>()
                        .add(SelectHubIntent(code)),
                  ),
                _ => const SizedBox.shrink(),
              },
              const SizedBox(height: 12),
              switch (state) {
                HubIntentsReady(
                  venuesPhase: HubIntentVenuesPhase.loading
                ) =>
                  const IntentVenuesLoadingRow(),
                HubIntentsReady(
                  venuesPhase: HubIntentVenuesPhase.loaded,
                  :final venues,
                  :final hasNoMatches,
                ) =>
                  IntentVenuesList(
                    venues: venues,
                    hasNoMatches: hasNoMatches,
                  ),
                HubIntentsReady(
                  venuesPhase: HubIntentVenuesPhase.error,
                  :final selectedCode,
                ) =>
                  IntentVenuesErrorRow(
                    onRetry: () => context
                        .read<HubIntentsBloc>()
                        .add(SelectHubIntent(selectedCode!)),
                  ),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        );
      },
    );
  }
}
