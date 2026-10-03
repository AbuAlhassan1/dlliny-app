part of 'intents_bloc.dart';

sealed class HubIntentsState {
  const HubIntentsState();
}

final class HubIntentsInitial extends HubIntentsState {
  const HubIntentsInitial();
}

final class HubIntentsListLoading extends HubIntentsState {
  const HubIntentsListLoading();
}

final class HubIntentsError extends HubIntentsState {
  const HubIntentsError();
}

final class HubIntentsReady extends HubIntentsState {
  final List<IntentResponse> intents;

  final String? selectedCode;
  final HubIntentVenuesPhase venuesPhase;
  final List<VenueSummaryResponse> venues;
  final bool hasNoMatches;

  final bool isRefreshing;

  const HubIntentsReady({
    required this.intents,
    required this.selectedCode,
    required this.venuesPhase,
    required this.venues,
    required this.hasNoMatches,
    this.isRefreshing = false,
  });
}

enum HubIntentVenuesPhase { idle, loading, loaded, error }
