part of 'venue_gallery_bloc.dart';

sealed class VenueGalleryEvent {
  const VenueGalleryEvent();
}

final class VenueGalleryRequested extends VenueGalleryEvent {
  const VenueGalleryRequested();
}

final class VenueGalleryTagSelected extends VenueGalleryEvent {
  final String? tag;
  const VenueGalleryTagSelected(this.tag);
}

final class VenueGalleryBranchSelected extends VenueGalleryEvent {
  final String? locationId;
  const VenueGalleryBranchSelected(this.locationId);
}
