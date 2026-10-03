part of 'update_logo_bloc.dart';

sealed class UpdateLogoState {}

final class UpdateLogoInitial extends UpdateLogoState {}
final class UpdateLogoLoading extends UpdateLogoState {}
final class UpdateLogoLoaded extends UpdateLogoState {
  final BusinessVenueResponse venue;
  UpdateLogoLoaded(this.venue);
}
final class UpdateLogoError extends UpdateLogoState {
  final String message;
  UpdateLogoError(this.message);
}
