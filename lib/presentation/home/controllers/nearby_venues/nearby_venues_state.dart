part of 'nearby_venues_bloc.dart';

sealed class NearbyVenuesState {
  const NearbyVenuesState();
}

final class NearbyVenuesInitial extends NearbyVenuesState {
  const NearbyVenuesInitial();
}

final class NearbyVenuesLoading extends NearbyVenuesState {
  const NearbyVenuesLoading();
}

final class NearbyVenuesLoaded extends NearbyVenuesState {
  final List<VenueSummaryResponse> items;
  final String? locationName;
  const NearbyVenuesLoaded(this.items, {this.locationName});
}

final class NearbyVenuesEmpty extends NearbyVenuesState {
  const NearbyVenuesEmpty();
}

final class NearbyVenuesError extends NearbyVenuesState {
  const NearbyVenuesError();
}

final class NearbyVenuesLocationDisabled extends NearbyVenuesState {
  const NearbyVenuesLocationDisabled();
}

final class NearbyVenuesPermissionDenied extends NearbyVenuesState {
  final bool canRetry;
  const NearbyVenuesPermissionDenied({required this.canRetry});
}
