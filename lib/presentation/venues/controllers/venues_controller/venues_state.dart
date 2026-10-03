part of 'venues_bloc.dart';

sealed class VenuesState {}

final class VenuesInitial extends VenuesState {}

final class GetVenuesLoading extends VenuesState {}
final class GetVenuesLoaded extends VenuesState {
  final List<BusinessVenueResponse> response;
  GetVenuesLoaded(this.response);
}
final class GetVenuesError extends VenuesState {
  final String message;
  GetVenuesError(this.message);
}
