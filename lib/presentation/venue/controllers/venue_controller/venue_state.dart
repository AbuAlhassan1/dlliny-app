part of 'venue_bloc.dart';

sealed class VenueState {}

final class VenueInitial extends VenueState {}
final class GetVenueDetailsLoading extends VenueState {}
final class GetVenueDetailsLoaded extends VenueState {
  final VenueResponse venue;

  GetVenueDetailsLoaded(this.venue);
}
final class GetVenueDetailsError extends VenueState {
  final String message;

  GetVenueDetailsError(this.message);
}
