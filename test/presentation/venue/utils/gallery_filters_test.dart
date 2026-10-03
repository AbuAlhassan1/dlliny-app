import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/presentation/venue/utils/gallery_filters.dart';

import '../../../helpers/gallery_test_helper.dart';

void main() {
  final wide = buildGalleryPhoto('wide', tags: ['inside', 'seating']);
  final karrada = buildGalleryPhoto(
    'karrada',
    tags: ['outside', 'hookah_lounge'],
    locationId: 'b-karrada',
  );
  final mansour = buildGalleryPhoto(
    'mansour',
    tags: ['inside'],
    locationId: 'b-mansour',
  );
  final all = [wide, karrada, mansour];

  List<String> ids(List<GalleryPhotoDto> photos) => [
    for (final p in photos) p.id,
  ];

  test('a branch shows its own photos plus the venue-wide ones', () {
    expect(ids(photosForBranch(all, null)), ['wide', 'karrada', 'mansour']);
    expect(ids(photosForBranch(all, 'b-karrada')), ['wide', 'karrada']);
    expect(ids(photosForBranch(all, 'b-mansour')), ['wide', 'mansour']);
    expect(ids(photosForBranch(all, 'b-other')), ['wide']);
  });

  test('tag filter keeps gallery order', () {
    expect(ids(photosWithTag(all, null)), ['wide', 'karrada', 'mansour']);
    expect(ids(photosWithTag(all, 'inside')), ['wide', 'mansour']);
    expect(ids(photosWithTag(all, 'view')), isEmpty);
  });

  test('counts only known tags, in vocabulary order', () {
    final counts = countKnownTags(all);
    expect(counts.keys, ['inside', 'outside', 'seating']);
    expect(counts, {'inside': 2, 'outside': 1, 'seating': 1});
    expect(counts.containsKey('hookah_lounge'), isFalse);
  });

  test('layoutRatio guards impossible dimensions and clamps to 5:1', () {
    expect(layoutRatio(buildGalleryPhoto('p')), closeTo(0.75, 1e-9));
    expect(
      layoutRatio(
        const GalleryPhotoDto(
          id: 'z',
          url: 'u',
          width: 0,
          height: 0,
          aspectRatio: 0,
        ),
      ),
      1,
    );
    expect(
      layoutRatio(buildGalleryPhoto('pano', width: 9000, height: 1000)),
      5,
    );
  });
}
