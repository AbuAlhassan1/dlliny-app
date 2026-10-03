import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';

import '../../../helpers/locale_test_helper.dart';

void main() {
  test('the vocabulary mirrors the server CHECK (8 codes, no food / menu)', () {
    expect(kGalleryTags, [
      'inside',
      'outside',
      'seating',
      'ambience',
      'facade',
      'view',
      'family_section',
      'private_room',
    ]);
    expect(kGalleryMaxPhotos, 24);
    expect(kGalleryMaxTagsPerPhoto, 3);
    expect(kGalleryMaxBytes, 10 * 1024 * 1024);
  });

  test('knownTags drops unknown codes and duplicates, keeps order', () {
    expect(knownTags(['view', 'rooftop', 'inside', 'view']), [
      'view',
      'inside',
    ]);
    expect(knownTags(const []), isEmpty);
  });

  test('knownTagCounts drops unknown codes and zeros, in vocabulary order', () {
    final counts = knownTagCounts({
      'view': 1,
      'rooftop': 5,
      'inside': 6,
      'seating': 0,
      'outside': 4,
    });
    expect(counts.keys, ['inside', 'outside', 'view']);
    expect(counts.values, [6, 4, 1]);
  });

  test('the privacy hint follows family_section / private_room', () {
    expect(needsPrivacyHint(['inside', 'family_section']), isTrue);
    expect(needsPrivacyHint(['private_room']), isTrue);
    expect(needsPrivacyHint(['inside', 'view']), isFalse);
  });

  test('labels come from the catalog; an unknown code has none', () async {
    await loadTestLocale('ar');
    expect(galleryTagLabel('inside'), 'من الداخل');
    expect(galleryTagLabel('family_section'), 'قسم العوائل');
    expect(galleryTagLabel('rooftop'), '');
    await loadTestLocale('en');
    expect(galleryTagLabel('facade'), 'Entrance & facade');
    for (final t in kGalleryTags) {
      expect(galleryTagLabel(t), isNot(contains('venue.gallery')), reason: t);
    }
  });
}
