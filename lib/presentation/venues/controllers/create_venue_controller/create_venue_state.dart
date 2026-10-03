part of 'create_venue_bloc.dart';

sealed class CreateVenueState {}

final class CreateVenueInitial extends CreateVenueState {}
final class CreateVenueLoading extends CreateVenueState {}
final class CreateVenueSuccess extends CreateVenueState {
  final BusinessVenueResponse response;
  CreateVenueSuccess(this.response);
}
final class CreateVenueError extends CreateVenueState {
  final String message;
  CreateVenueError(this.message);
}
