part of 'venue_bloc.dart';

sealed class VenueEvent {}
class GetVenueDetails extends VenueEvent {
  final String id;

  GetVenueDetails(this.id);
}