part of 'venue_background_media_bloc.dart';

sealed class VenueBackgroundMediaState {}

final class VenueBackgroundMediaInitial extends VenueBackgroundMediaState {}
final class VenueBackgroundMediaLoading extends VenueBackgroundMediaState {}
final class VenueBackgroundMediaLoaded extends VenueBackgroundMediaState {
  final BusinessVenueResponse venue;
  VenueBackgroundMediaLoaded(this.venue);
}
final class VenueBackgroundMediaError extends VenueBackgroundMediaState {
  final String message;
  VenueBackgroundMediaError(this.message);
}
