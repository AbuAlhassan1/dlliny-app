part of 'nearby_venues_bloc.dart';

sealed class NearbyVenuesEvent {}

class LoadNearbyVenues extends NearbyVenuesEvent {
  final int? radiusMeters;
  final int? limit;
  LoadNearbyVenues({this.radiusMeters, this.limit});
}

class RequestNearbyVenuesPermission extends NearbyVenuesEvent {}
