part of 'services_bloc.dart';

sealed class ServicesEvent {}

class GetServices extends ServicesEvent {
  final String venueId;
  GetServices(this.venueId);
}
