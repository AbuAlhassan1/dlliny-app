import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';

List<GalleryPhotoDto> photosForBranch(
  List<GalleryPhotoDto> photos,
  String? locationId,
) {
  if (locationId == null) return photos;
  return [
    for (final p in photos)
      if (p.locationId == null || p.locationId == locationId) p,
  ];
}

List<GalleryPhotoDto> photosWithTag(List<GalleryPhotoDto> photos, String? tag) {
  if (tag == null) return photos;
  return [
    for (final p in photos)
      if (p.tags.contains(tag)) p,
  ];
}

Map<String, int> countKnownTags(List<GalleryPhotoDto> photos) {
  final counts = <String, int>{};
  for (final p in photos) {
    for (final t in knownTags(p.tags)) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  return knownTagCounts(counts);
}

double layoutRatio(GalleryPhotoDto photo) {
  final r = photo.ratio;
  if (!r.isFinite || r <= 0) return 1;
  return r.clamp(0.2, 5.0);
}
