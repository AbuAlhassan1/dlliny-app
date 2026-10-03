part of 'nearby_discovery_bloc.dart';

sealed class NearbyDiscoveryState {
  const NearbyDiscoveryState();

  bool? get discoverable => null;
}

final class NearbyDiscoveryInitial extends NearbyDiscoveryState {
  const NearbyDiscoveryInitial();
}

final class NearbyDiscoveryLoading extends NearbyDiscoveryState {
  const NearbyDiscoveryLoading();
}

final class NearbyDiscoveryUnavailable extends NearbyDiscoveryState {
  const NearbyDiscoveryUnavailable();
}

final class NearbyDiscoveryReady extends NearbyDiscoveryState {
  @override
  final bool discoverable;

  final bool justChanged;

  const NearbyDiscoveryReady({
    required this.discoverable,
    this.justChanged = false,
  });
}

final class NearbyDiscoveryUpdating extends NearbyDiscoveryState {
  @override
  final bool discoverable;

  const NearbyDiscoveryUpdating({required this.discoverable});
}

final class NearbyDiscoveryError extends NearbyDiscoveryState {
  final String message;

  @override
  final bool discoverable;

  const NearbyDiscoveryError(this.message, {required this.discoverable});
}
