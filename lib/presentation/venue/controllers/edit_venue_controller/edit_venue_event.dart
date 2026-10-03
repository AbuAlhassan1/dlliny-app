part of 'edit_venue_bloc.dart';

sealed class EditVenueEvent {}

class EditVenue extends EditVenueEvent {
  final String venueId;
  final UpdateBusinessVenueRequest request;
  EditVenue({required this.venueId, required this.request});
}
