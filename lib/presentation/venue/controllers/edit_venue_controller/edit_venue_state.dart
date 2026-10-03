part of 'edit_venue_bloc.dart';

sealed class EditVenueState {}

final class EditVenueInitial extends EditVenueState {}
final class EditVenueLoading extends EditVenueState {}
final class EditVenueSuccess extends EditVenueState {}
final class EditVenueError extends EditVenueState {
  final String message;
  EditVenueError(this.message);
}
