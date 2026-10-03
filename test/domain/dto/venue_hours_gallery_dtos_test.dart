import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/domain/dto/request/gallery_requests.dart';
import 'package:hangout/domain/dto/request/venue_hours_requests.dart';
import 'package:hangout/domain/dto/response/business_gallery_response.dart';
import 'package:hangout/domain/dto/response/business_venue_hours_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';

Map<String, dynamic> _status(String state) => {
  'state': state,
  'openNow': state == 'OPEN',
  'closingSoon': false,
  'openingSoon': false,
  'alwaysOpen': false,
  'closesAt': null,
  'opensAt': null,
  'nextChangeAt': null,
  'season': 'REGULAR',
  'reopensOn': null,
  'spanOperatingDate': null,
  'spanSeason': null,
};

Map<String, dynamic> _week() => {
  'days': [
    for (var d = 0; d < 7; d++)
      {
        'dayOfWeek': d,
        'kind': d == 5 ? 'CLOSED' : 'HOURS',
        'intervals': d == 5
            ? []
            : [
                {'opens': '09:00', 'closes': '02:00', 'overnight': true},
              ],
      },
  ],
};

Map<String, dynamic> _editorModel({bool withToday = true}) => {
  'venueId': '9f2c',
  'timezone': 'Asia/Baghdad',
  'evaluatedAt': '2026-09-28T21:40:00+03:00',
  if (withToday) 'today': '2026-09-28',
  'ramadanWindow': {
    'startsOn': '2027-02-08',
    'endsOn': '2027-03-09',
    'active': false,
  },
  'venue': {
    'locationId': null,
    'labelAr': null,
    'labelEn': null,
    'districtNameAr': null,
    'districtNameEn': null,
    'isPrimary': false,
    'hoursMode': 'OWN',
    'statusMode': 'OWN',
    'operatingStatus': 'OPEN',
    'reopensOn': null,
    'statusExpired': false,
    'regular': _week(),
    'ramadan': null,
    'effectiveStatus': _status('OPEN'),
    'hoursUpdatedAt': '2026-09-20T10:12:44Z',
  },
  'branches': [
    {
      'locationId': '6b1f',
      'labelAr': 'الكرادة',
      'labelEn': 'Karrada',
      'districtNameAr': 'الكرادة',
      'districtNameEn': 'Karrada',
      'isPrimary': true,
      'hoursMode': 'INHERIT',
      'statusMode': 'INHERIT',
      'operatingStatus': null,
      'reopensOn': null,
      'statusExpired': false,
      'regular': null,
      'ramadan': null,
      'effectiveStatus': _status('OPEN'),
      'hoursUpdatedAt': null,
    },
    {
      'locationId': 'c0d9',
      'labelAr': null,
      'labelEn': null,
      'districtNameAr': 'المنصور',
      'districtNameEn': 'Mansour',
      'isPrimary': false,
      'hoursMode': 'OWN',
      'statusMode': 'OWN',
      'operatingStatus': 'TEMPORARILY_CLOSED',
      'reopensOn': '2026-09-27',
      'statusExpired': true,
      'regular': _week(),
      'ramadan': null,
      'effectiveStatus': _status('OPEN'),
      'hoursUpdatedAt': '2026-09-22T08:01:10Z',
    },
  ],
};

void main() {
  group('BusinessVenueHoursResponse', () {
    test('parses the editor model, venue scope with null branch fields', () {
      final r = BusinessVenueHoursResponse.fromJson(_editorModel());
      expect(r.baghdadToday, '2026-09-28');
      expect(r.ramadanWindow!.startsOn, '2027-02-08');
      expect(r.ramadanWindow!.active, isFalse);

      expect(r.venue.locationId, isNull);
      expect(r.venue.labelAr, isNull);
      expect(r.venue.districtNameAr, isNull);
      expect(r.venue.isPrimary, isFalse);
      expect(r.venue.ownsHours, isTrue);
      expect(r.venue.regular!.days, hasLength(7));
      expect(r.venue.effectiveStatus.state, OpenState.open);

      expect(r.branches, hasLength(2));
      final karrada = r.branch('6b1f')!;
      expect(karrada.ownsHours, isFalse);
      expect(karrada.ownsStatus, isFalse);
      expect(karrada.regular, isNull);
      expect(karrada.hoursUpdatedAt, isNull);

      final mansour = r.branch('c0d9')!;
      expect(mansour.labelAr, isNull);
      expect(mansour.districtNameAr, 'المنصور');
      expect(mansour.statusExpired, isTrue);
      expect(mansour.operatingStatus, VenueOperatingStatus.temporarilyClosed);
    });

    test('baghdadToday falls back to the date part of evaluatedAt', () {
      final r = BusinessVenueHoursResponse.fromJson(
        _editorModel(withToday: false),
      );
      expect(r.today, isNull);
      expect(r.baghdadToday, '2026-09-28');
    });
  });

  group('gallery responses', () {
    test(
      'BusinessGalleryResponse parses hidden photos and upload metadata',
      () {
        final r = BusinessGalleryResponse.fromJson({
          'photos': [
            {
              'id': 'p1',
              'url': 'https://cdn/venues/v/gallery/p1.webp',
              'width': 2048,
              'height': 1536,
              'aspectRatio': 1.3333,
              'placeholderHash': null,
              'tags': ['view', 'food'],
              'locationId': 'c0d9',
              'sortOrder': 3,
              'createdAt': '2026-09-27T18:03:11Z',
              'hidden': true,
              'hiddenReason': 'Identifiable guests without consent',
              'hiddenAt': '2026-09-28T08:00:00Z',
              'contentType': 'image/webp',
              'byteSize': 412933,
              'uploadedByUserId': 'u1',
            },
          ],
          'maxPhotos': 24,
          'remaining': 23,
          'privacyHintTags': ['family_section', 'private_room'],
        });
        final p = r.photos.single;
        expect(p.hidden, isTrue);
        expect(p.hiddenReason, 'Identifiable guests without consent');
        expect(p.byteSize, 412933);
        expect(p.contentType, 'image/webp');
        expect(p.uploadedByUserId, 'u1');
        expect(p.locationId, 'c0d9');
        expect(p.sortOrder, 3);
        expect(r.maxPhotos, 24);
        expect(r.remaining, 23);
        expect(r.privacyHintTags, ['family_section', 'private_room']);
      },
    );

    test('privacyHintTags is optional', () {
      final r = BusinessGalleryResponse.fromJson({
        'photos': [],
        'maxPhotos': 24,
        'remaining': 24,
      });
      expect(r.privacyHintTags, isEmpty);
    });

    test('GalleryUploadUrlResponse parses', () {
      final r = GalleryUploadUrlResponse.fromJson({
        'uploadUrl': 'https://s3/put',
        'key': 'venues/v/gallery/0d6f0c3a-4b8e-4a5e-9c55-2f1c4c1b1f11.webp',
        'expiresInSeconds': 300,
        'maxBytes': 10485760,
      });
      expect(r.expiresInSeconds, 300);
      expect(r.maxBytes, 10485760);
    });
  });

  group('hours requests', () {
    final week = WeeklyScheduleInput.fromDto(
      WeeklyScheduleDto.fromJson(_week()),
    );

    test('fromDto keeps days and maps kinds to their wire strings', () {
      expect(week.days, hasLength(7));
      expect(week.days[5].kind, 'CLOSED');
      expect(week.days[5].intervals, isEmpty);
      expect(week.days[0].kind, 'HOURS');
      expect(week.days[0].intervals.single.toJson(), {
        'opens': '09:00',
        'closes': '02:00',
      });
      expect(HoursDayKind.open24h.wire, 'OPEN_24H');
    });

    test(
      'a regular-only save sends no ramadan and no removeRamadan (KEEP)',
      () {
        final json = UpdateVenueHoursRequest(regular: week).toJson();
        expect(json.keys, ['regular']);
        expect((json['regular'] as Map)['days'], hasLength(7));
      },
    );

    test('removing the Ramadan week sends removeRamadan: true', () {
      final json = UpdateVenueHoursRequest(
        regular: week,
        removeRamadan: true,
      ).toJson();
      expect(json['removeRamadan'], isTrue);
      expect(json.containsKey('ramadan'), isFalse);
    });

    test('replacing the Ramadan week sends it', () {
      final json = UpdateVenueHoursRequest(
        regular: week,
        ramadan: week,
      ).toJson();
      expect(json.containsKey('ramadan'), isTrue);
      expect(json.containsKey('removeRamadan'), isFalse);
    });

    test('branch INHERIT carries the mode only', () {
      expect(
        const UpdateBranchHoursRequest(mode: HoursScopeMode.inherit).toJson(),
        {'mode': 'INHERIT'},
      );
      expect(
        const UpdateBranchOperatingStatusRequest(
          mode: HoursScopeMode.inherit,
        ).toJson(),
        {'mode': 'INHERIT'},
      );
    });

    test('status writes omit an absent reopensOn', () {
      expect(
        const UpdateOperatingStatusRequest(
          status: VenueOperatingStatus.open,
        ).toJson(),
        {'status': 'OPEN'},
      );
      expect(
        const UpdateOperatingStatusRequest(
          status: VenueOperatingStatus.temporarilyClosed,
          reopensOn: '2026-10-06',
        ).toJson(),
        {'status': 'TEMPORARILY_CLOSED', 'reopensOn': '2026-10-06'},
      );
    });
  });

  group('gallery requests', () {
    test('attach omits a null placeholder and branch, keeps empty tags', () {
      final json = const AttachGalleryPhotoRequest(
        key: 'venues/v/gallery/k.jpg',
        width: 1536,
        height: 2048,
      ).toJson();
      expect(json, {
        'key': 'venues/v/gallery/k.jpg',
        'width': 1536,
        'height': 2048,
        'tags': <String>[],
      });
    });

    test('patch sends only what changes; NIL UUID clears the branch', () {
      expect(
        const UpdateGalleryPhotoRequest(
          venueLocationId: kClearVenueLocationId,
        ).toJson(),
        {'venueLocationId': '00000000-0000-0000-0000-000000000000'},
      );
      expect(const UpdateGalleryPhotoRequest(tags: []).toJson(), {
        'tags': <String>[],
      });
    });

    test('reorder sends the ids in order', () {
      expect(const ReorderGalleryRequest(photoIds: ['b', 'a']).toJson(), {
        'photoIds': ['b', 'a'],
      });
    });
  });
}
