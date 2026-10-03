part of 'venue_products_bloc.dart';

sealed class VenueProductsEvent {
  const VenueProductsEvent();
}

class LoadVenueProducts extends VenueProductsEvent {
  const LoadVenueProducts();
}

class LoadNextVenueProductsPage extends VenueProductsEvent {
  const LoadNextVenueProductsPage();
}
