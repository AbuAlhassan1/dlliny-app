part of 'cities_and_districts_bloc.dart';

sealed class CitiesAndDistrictsState {}

final class CitiesAndDistrictsInitial extends CitiesAndDistrictsState {}
final class CitiesAndDistrictsLoading extends CitiesAndDistrictsState {}
final class CitiesAndDistrictsLoaded extends CitiesAndDistrictsState {
  final List<CityWithDistrictsDto> response;
  CitiesAndDistrictsLoaded(this.response);
}
final class CitiesAndDistrictsError extends CitiesAndDistrictsState {
  final String message;
  CitiesAndDistrictsError(this.message);
}
