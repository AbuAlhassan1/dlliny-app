import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_photo_image.dart';

import '../../helpers/gallery_test_helper.dart';
import '../../helpers/locale_test_helper.dart';

void main() {
  setUpAll(() => loadTestLocale('ar'));

  group('galleryCoverDecodeWidth', () {
    const tile = Size(128.67, 171.56);
    const dpr = 3.0;

    test('a landscape photo in a portrait tile decodes wide enough to '
        'cover its HEIGHT, not just its width', () {
      final landscape = buildGalleryPhoto('l', width: 2048, height: 1536);
      final width = galleryCoverDecodeWidth(landscape, tile, dpr)!;
      expect(width, greaterThanOrEqualTo(tile.height * 4 / 3 * dpr));
      expect(width * 3 / 4, greaterThanOrEqualTo(tile.height * dpr - 0.5));
      expect(width, greaterThan((tile.width * dpr).round()));
    });

    test('a 16:9 photo in a portrait tile', () {
      final wide = buildGalleryPhoto('w', width: 3840, height: 2160);
      expect(
        galleryCoverDecodeWidth(wide, tile, dpr),
        closeTo(tile.height * 16 / 9 * dpr, 1),
      );
    });

    test('a portrait photo in a portrait tile: the tile width', () {
      final portrait = buildGalleryPhoto('p', width: 1536, height: 2048);
      expect(
        galleryCoverDecodeWidth(portrait, tile, dpr),
        (tile.width * dpr).ceil(),
      );
    });

    test('a panorama in the single-photo row (16:9 box)', () {
      final pano = buildGalleryPhoto('pano', width: 4000, height: 1000);
      const row = Size(360, 202.5);
      expect(galleryCoverDecodeWidth(pano, row, dpr), (202.5 * 4 * 3).ceil());
    });

    test('never above the original width', () {
      final small = buildGalleryPhoto('s', width: 400, height: 300);
      expect(galleryCoverDecodeWidth(small, tile, dpr), 400);
    });

    test('an unbounded height falls back to the width; an unusable width '
        'decodes at full size', () {
      final photo = buildGalleryPhoto('l', width: 2048, height: 1536);
      expect(
        galleryCoverDecodeWidth(photo, const Size(100, double.infinity), 2),
        200,
      );
      expect(
        galleryCoverDecodeWidth(photo, const Size(double.infinity, 100), 2),
        isNull,
      );
      expect(galleryCoverDecodeWidth(photo, Size.zero, 2), isNull);
    });
  });

  group('galleryPhotoSemanticLabel', () {
    test('known tags, then the position', () {
      final photo = buildGalleryPhoto(
        'a',
        tags: ['inside', 'hookah_lounge', 'seating'],
      );
      expect(
        galleryPhotoSemanticLabel(photo, index: 1, total: 9),
        'من الداخل، الجلسات · 2 من 9',
      );
    });

    test('no known tag: the position alone', () {
      final photo = buildGalleryPhoto('a', tags: ['hookah_lounge']);
      expect(galleryPhotoSemanticLabel(photo, index: 0, total: 3), '1 من 3');
    });
  });
}
