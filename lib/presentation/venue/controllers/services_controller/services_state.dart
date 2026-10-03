part of 'services_bloc.dart';

sealed class ServicesState {}

final class ServicesInitial extends ServicesState {}
final class ServicesLoading extends ServicesState {}
final class ServicesLoaded extends ServicesState {
  final List<VenueServiceItemDto> response;
  ServicesLoaded(this.response);
}
final class ServicesError extends ServicesState {
  final String message;
  ServicesError(this.message);
}
