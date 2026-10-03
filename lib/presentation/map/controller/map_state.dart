part of 'map_bloc.dart';

@immutable
sealed class MapState {}

final class MapInitial extends MapState {}

final class MapVenuesLoading extends MapState {}
final class MapVenuesLoaded extends MapState {}
final class MapVenuesError extends MapState {
  final String message;
  MapVenuesError(this.message);
}

final class VenueSearchLoading extends MapState {}
final class VenueSearchLoaded extends MapState {}
final class VenueSearchCleared extends MapState {}
final class VenueSearchError extends MapState {
  final String message;
  VenueSearchError(this.message);
}

final class MapCategoriesLoaded extends MapState {}

final class MapCategoriesLoading extends MapState {}

final class MapCategoryFilterChanged extends MapState {}

final class ShakeLoading extends MapState {}

final class ShakeLoaded extends MapState {
  final String mode;
  final String status;
  final List<ShakeRecommendationItem> items;
  ShakeLoaded({
    required this.mode,
    required this.status,
    required this.items,
  });
}

final class ShakeError extends MapState {
  final String message;
  final bool rateLimited;
  ShakeError(this.message, {this.rateLimited = false});
}
