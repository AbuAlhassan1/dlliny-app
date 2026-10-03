part of 'manage_gallery_bloc.dart';

sealed class ManageGalleryEvent {
  const ManageGalleryEvent();
}

final class GalleryLoadRequested extends ManageGalleryEvent {
  const GalleryLoadRequested();
}

final class GalleryPhotosPicked extends ManageGalleryEvent {
  final List<XFile> files;
  final List<String> tags;

  final String? locationId;

  const GalleryPhotosPicked(
    this.files, {
    this.tags = const [],
    this.locationId,
  });
}

final class GalleryUploadRetried extends ManageGalleryEvent {
  final int localId;
  const GalleryUploadRetried(this.localId);
}

final class GalleryUploadDismissed extends ManageGalleryEvent {
  final int localId;
  const GalleryUploadDismissed(this.localId);
}

final class GalleryUploadsCancelled extends ManageGalleryEvent {
  const GalleryUploadsCancelled();
}

final class GalleryPhotoEdited extends ManageGalleryEvent {
  final String photoId;
  final List<String>? tags;
  final String? venueLocationId;

  const GalleryPhotoEdited(this.photoId, {this.tags, this.venueLocationId});
}

final class GalleryReorderCommitted extends ManageGalleryEvent {
  final List<String> photoIds;
  const GalleryReorderCommitted(this.photoIds);
}

final class GalleryPhotoDeleted extends ManageGalleryEvent {
  final String photoId;
  const GalleryPhotoDeleted(this.photoId);
}
