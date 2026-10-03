part of 'venues_categories_bloc.dart';

sealed class VenuesCategoriesState {}

final class VenuesCategoriesInitial extends VenuesCategoriesState {}

final class VenuesCategoriesLoading extends VenuesCategoriesState {}
final class VenuesCategoriesLoaded extends VenuesCategoriesState {
  final List<VenueCategoryDto> response;
  VenuesCategoriesLoaded(this.response);
}
final class VenuesCategoriesError extends VenuesCategoriesState {
  final String message;
  VenuesCategoriesError(this.message);
}
