import 'package:easy_localization/easy_localization.dart';
import 'package:hangout/generated/locale_keys.g.dart';

const List<String> kGalleryTags = [
  'inside',
  'outside',
  'seating',
  'ambience',
  'facade',
  'view',
  'family_section',
  'private_room',
];

const Set<String> kPrivacyHintTags = {'family_section', 'private_room'};

const int kGalleryMaxPhotos = 24;

const int kGalleryMaxTagsPerPhoto = 3;

const int kGalleryMaxBytes = 10485760;

const List<String> kGalleryContentTypes = [
  'image/jpeg',
  'image/png',
  'image/webp',
];

List<String> knownTags(List<String> tags) {
  final seen = <String>{};
  return [
    for (final t in tags)
      if (kGalleryTags.contains(t) && seen.add(t)) t,
  ];
}

Map<String, int> knownTagCounts(Map<String, int> counts) => {
  for (final t in kGalleryTags)
    if ((counts[t] ?? 0) > 0) t: counts[t]!,
};

bool needsPrivacyHint(Iterable<String> tags) =>
    tags.any(kPrivacyHintTags.contains);

String galleryTagLabel(String code) => switch (code) {
  'inside' => LocaleKeys.venue_gallery_tags_inside.tr(),
  'outside' => LocaleKeys.venue_gallery_tags_outside.tr(),
  'seating' => LocaleKeys.venue_gallery_tags_seating.tr(),
  'ambience' => LocaleKeys.venue_gallery_tags_ambience.tr(),
  'facade' => LocaleKeys.venue_gallery_tags_facade.tr(),
  'view' => LocaleKeys.venue_gallery_tags_view.tr(),
  'family_section' => LocaleKeys.venue_gallery_tags_family_section.tr(),
  'private_room' => LocaleKeys.venue_gallery_tags_private_room.tr(),
  _ => '',
};
