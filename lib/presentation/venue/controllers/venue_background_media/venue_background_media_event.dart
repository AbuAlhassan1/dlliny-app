part of 'venue_background_media_bloc.dart';

sealed class VenueBackgroundMediaEvent {}

class UpdateVenueCover extends VenueBackgroundMediaEvent {
  final String venueId;
  final File file;
  UpdateVenueCover({required this.venueId, required this.file});
}

class DeleteVenueCover extends VenueBackgroundMediaEvent {
  final String venueId;
  DeleteVenueCover({required this.venueId});
}
