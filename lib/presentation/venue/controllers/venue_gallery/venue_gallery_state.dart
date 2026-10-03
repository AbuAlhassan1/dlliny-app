part of 'venue_gallery_bloc.dart';

enum VenueGalleryStatus { loading, ready, error }

final class VenueGalleryState {
  final VenueGalleryStatus status;

  final List<GalleryPhotoDto> photos;

  final String? tag;

  final String? locationId;

  const VenueGalleryState({
    required this.status,
    this.photos = const [],
    this.tag,
    this.locationId,
  });

  List<GalleryPhotoDto> get branchPhotos => photosForBranch(photos, locationId);

  List<GalleryPhotoDto> get visible => photosWithTag(branchPhotos, tag);

  Map<String, int> get tagCounts => countKnownTags(branchPhotos);

  VenueGalleryState copyWith({
    VenueGalleryStatus? status,
    List<GalleryPhotoDto>? photos,
    String? Function()? tag,
    String? Function()? locationId,
  }) => VenueGalleryState(
    status: status ?? this.status,
    photos: photos ?? this.photos,
    tag: tag == null ? this.tag : tag(),
    locationId: locationId == null ? this.locationId : locationId(),
  );
}
