part of 'create_venue_bloc.dart';

sealed class CreateVenueEvent {}

class CreateVenue extends CreateVenueEvent {
  final String businessId;
  final CreateBusinessVenueRequest request;

  CreateVenue(this.businessId, this.request);
}
