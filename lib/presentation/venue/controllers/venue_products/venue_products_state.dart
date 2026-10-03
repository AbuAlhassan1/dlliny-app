part of 'venue_products_bloc.dart';

sealed class VenueProductsState {
  const VenueProductsState();
}

final class VenueProductsInitial extends VenueProductsState {
  const VenueProductsInitial();
}

final class VenueProductsLoading extends VenueProductsState {
  const VenueProductsLoading();
}

final class VenueProductsError extends VenueProductsState {
  final String message;
  const VenueProductsError(this.message);
}

final class VenueProductsLoaded extends VenueProductsState {
  final List<PostResponse> items;
  final bool hasMore;
  const VenueProductsLoaded({required this.items, required this.hasMore});
}
