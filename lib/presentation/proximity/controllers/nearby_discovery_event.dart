part of 'nearby_discovery_bloc.dart';

sealed class NearbyDiscoveryEvent {
  const NearbyDiscoveryEvent();
}

final class LoadNearbyDiscovery extends NearbyDiscoveryEvent {
  const LoadNearbyDiscovery();
}

final class ToggleNearbyDiscovery extends NearbyDiscoveryEvent {
  final bool discoverable;
  const ToggleNearbyDiscovery({required this.discoverable});
}
