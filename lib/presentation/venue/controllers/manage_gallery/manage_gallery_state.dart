part of 'manage_gallery_bloc.dart';

enum ManageGalleryStatus { loading, ready, error }

enum GalleryUploadStatus {
  queued,
  preparing,
  uploading,
  attaching,
  done,
  failed,
}

final class GalleryUploadItem {
  final int localId;
  final XFile file;
  final List<String> tags;
  final String? locationId;
  final GalleryUploadStatus status;

  final String? errorCode;

  final String? key;

  final int? width;
  final int? height;
  final String? placeholderHash;

  const GalleryUploadItem({
    required this.localId,
    required this.file,
    this.tags = const [],
    this.locationId,
    this.status = GalleryUploadStatus.queued,
    this.errorCode,
    this.key,
    this.width,
    this.height,
    this.placeholderHash,
  });

  bool get isActive =>
      status != GalleryUploadStatus.done &&
      status != GalleryUploadStatus.failed;

  GalleryUploadItem copyWith({
    GalleryUploadStatus? status,
    String? Function()? locationId,
    String? Function()? errorCode,
    String? Function()? key,
    int? width,
    int? height,
    String? Function()? placeholderHash,
  }) => GalleryUploadItem(
    localId: localId,
    file: file,
    tags: tags,
    locationId: locationId == null ? this.locationId : locationId(),
    status: status ?? this.status,
    errorCode: errorCode == null ? this.errorCode : errorCode(),
    key: key == null ? this.key : key(),
    width: width ?? this.width,
    height: height ?? this.height,
    placeholderHash: placeholderHash == null
        ? this.placeholderHash
        : placeholderHash(),
  );
}

final class ManageGalleryNotice {
  final int serial;

  final String? code;

  final bool branchCleared;

  const ManageGalleryNotice({
    required this.serial,
    this.code,
    this.branchCleared = false,
  });
}

final class ManageGalleryState {
  final ManageGalleryStatus status;

  final List<GalleryPhotoDto> photos;

  final int maxPhotos;

  final List<GalleryUploadItem> uploads;

  final int remaining;

  final bool busy;

  final bool changed;

  final ManageGalleryNotice? notice;

  const ManageGalleryState({
    this.status = ManageGalleryStatus.loading,
    this.photos = const [],
    this.maxPhotos = kGalleryMaxPhotos,
    this.uploads = const [],
    this.remaining = 0,
    this.busy = false,
    this.changed = false,
    this.notice,
  });

  bool get uploading => uploads.any((u) => u.isActive);

  List<GalleryUploadItem> get pendingUploads => [
    for (final u in uploads)
      if (u.status != GalleryUploadStatus.done) u,
  ];

  int get uploadsDone =>
      uploads.where((u) => u.status == GalleryUploadStatus.done).length;

  int get uploadsTotal =>
      uploads.where((u) => u.status != GalleryUploadStatus.failed).length;
}
