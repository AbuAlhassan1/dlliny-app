part of 'map_bloc.dart';

@immutable
sealed class MapEvent {}

class GetVenuesInViewport extends MapEvent {
  final double lat;
  final double lng;
  final int radiusMeters;
  GetVenuesInViewport({
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });
}

class SearchVenues extends MapEvent {
  final String query;
  SearchVenues(this.query);
}

class ClearVenueSearch extends MapEvent {}

class LoadMapCategories extends MapEvent {}

class SetMapCategoryFilter extends MapEvent {
  final int? categoryId;
  SetMapCategoryFilter(this.categoryId);
}

class ShakeRequested extends MapEvent {
  final String mode;
  final double lat;
  final double lng;
  final bool includeFar;
  ShakeRequested({
    required this.mode,
    required this.lat,
    required this.lng,
    this.includeFar = false,
  });
}

class ClearShakeResults extends MapEvent {}
