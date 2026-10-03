part of 'cities_and_districts_bloc.dart';

sealed class CitiesAndDistrictsEvent {}

class GetCities extends CitiesAndDistrictsEvent {}

class GetDistricts extends CitiesAndDistrictsEvent {
  final int cityId;
  GetDistricts(this.cityId);
}