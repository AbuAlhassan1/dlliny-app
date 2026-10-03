import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';

Map<String, dynamic> _fixture() =>
    jsonDecode(
          File('test/fixtures/venue_response_v106.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

const _karrada = '68d5c7be-7a14-44d7-83cb-9d59dac62764';
const _mansour = '600ecfc7-8f00-4743-95d8-15d82dce8c3f';

void main() {
  group('VenueResponse (V106 backend fixture)', () {
    late VenueResponse venue;

    setUp(() => venue = VenueResponse.fromJson(_fixture()));

    test('keeps the legacy hours and mediaUrls exactly as before', () {
      expect(venue.hours, hasLength(15));
      final first = venue.hours.first;
      expect(first.dayOfWeek, 0);
      expect(first.openTime, '09:00:00');
      expect(first.closed, isFalse);
      expect(first.ramadan, isFalse);
      expect(venue.mediaUrls, hasLength(1));
    });

    test('a null nameEn (nullable on the server) falls back to nameAr', () {
      expect(_fixture()['nameEn'], isNull);
      expect(venue.nameEn, 'مقهى الشناشيل');
    });

    test('the fallback is display-only: rawNameEn and toJson keep the null', () {
      expect(venue.rawNameEn, isNull);
      expect(venue.toJson()['nameEn'], isNull);

      final named = VenueResponse.fromJson({
        ..._fixture(),
        'nameEn': 'Shanasheel Cafe',
      });
      expect(named.nameEn, 'Shanasheel Cafe');
      expect(named.rawNameEn, 'Shanasheel Cafe');
      expect(named.toJson()['nameEn'], 'Shanasheel Cafe');
    });

    test(
      'parses openingHours: summary, today, weeks and the status moment',
      () {
        final oh = venue.openingHours!;
        expect(oh.timezone, 'Asia/Baghdad');
        expect(oh.evaluatedAt, '2026-09-28T21:40:00+03:00');
        expect(oh.ramadanWindow, isNull);

        final s = oh.summary;
        expect(s.locationId, _karrada);
        expect(s.hoursSource, HoursSource.venue);
        expect(s.statusSource, HoursSource.venue);
        expect(s.operatingStatus, VenueOperatingStatus.open);
        expect(s.hoursUpdatedAt, '2026-09-20T10:12:44Z');
        expect(s.lastNight, isNull);

        final st = s.status;
        expect(st.state, OpenState.open);
        expect(st.openNow, isTrue);
        expect(st.closingSoon, isFalse);
        expect(st.alwaysOpen, isFalse);
        expect(st.opensAt, isNull);
        expect(st.closesAt!.localTime, '02:00');
        expect(st.closesAt!.localDate, '2026-09-29');
        expect(st.closesAt!.dayOfWeek, 2);
        expect(st.closesAt!.dayOffset, 1);
        expect(st.nextChangeAt, '2026-09-29T02:00:00+03:00');
        expect(st.season, HoursSeason.regular);
        expect(st.spanOperatingDate, '2026-09-28');
        expect(st.spanSeason, HoursSeason.regular);

        final today = s.today!;
        expect(today.date, '2026-09-28');
        expect(today.dayOfWeek, 1);
        expect(today.kind, HoursDayKind.hours);
        expect(today.intervals.single.opens, '09:00');
        expect(today.intervals.single.closes, '02:00');
        expect(today.intervals.single.overnight, isTrue);
        expect(today.ramadanEveIntervals, isEmpty);

        expect(s.regular!.days, hasLength(7));
        expect(s.regular!.day(5)!.kind, HoursDayKind.closed);
        expect(s.regular!.day(6)!.kind, HoursDayKind.open24h);
        expect(s.regular!.day(0)!.intervals, hasLength(2));
        expect(s.ramadan!.days, hasLength(7));
      },
    );

    test('parses per-branch scopes; branch() / scopeFor() resolve them', () {
      final oh = venue.openingHours!;
      expect(oh.branches, hasLength(2));

      final mansour = oh.branch(_mansour)!;
      expect(mansour.hoursSource, HoursSource.branch);
      expect(mansour.ramadan, isNull);
      expect(mansour.status.closesAt!.localTime, '00:00');

      expect(oh.variesByBranch, isTrue);
      expect(oh.scopeFor(_mansour), same(mansour));
      expect(oh.scopeFor(null), same(oh.summary));
      expect(oh.scopeFor('not-a-branch'), same(oh.summary));
    });

    test('parses the embedded gallery', () {
      final g = venue.gallery!;
      expect(g.totalCount, 1);
      expect(g.tagCounts, {'inside': 1, 'seating': 1});
      final p = g.photos.single;
      expect(p.id, 'e3a130da-9982-4383-88a4-11ba771176c5');
      expect(p.width, 1536);
      expect(p.height, 2048);
      expect(p.ratio, 0.75);
      expect(p.placeholderHash, '3OcRJYB4d3h/iIeHeEh3eIhw+j2w');
      expect(p.tags, ['inside', 'seating']);
      expect(p.locationId, isNull);
      expect(p.hidden, isFalse);
    });

    test('survives a toJson → fromJson round trip (the local cache path)', () {
      final again = VenueResponse.fromJson(
        jsonDecode(jsonEncode(venue.toJson())) as Map<String, dynamic>,
      );
      expect(again.openingHours!.summary.status.closesAt!.localTime, '02:00');
      expect(again.openingHours!.branches, hasLength(2));
      expect(again.gallery!.photos.single.tags, ['inside', 'seating']);
      expect(again.nameEn, venue.nameEn);
      expect(again.rawNameEn, isNull);
    });
  });

  test(
    'a payload WITHOUT openingHours / gallery (older backend) parses to nulls',
    () {
      final json = _fixture()
        ..remove('openingHours')
        ..remove('gallery');
      final venue = VenueResponse.fromJson(json);
      expect(venue.openingHours, isNull);
      expect(venue.gallery, isNull);
      expect(venue.hours, hasLength(15));
      expect(venue.id, 'a185bdc1-93f0-410b-8060-6232eb8ca199');
    },
  );

  test('explicit nulls for the new fields also parse to nulls', () {
    final json = _fixture()
      ..['openingHours'] = null
      ..['gallery'] = null;
    final venue = VenueResponse.fromJson(json);
    expect(venue.openingHours, isNull);
    expect(venue.gallery, isNull);
  });

  group('values a later server may add never crash parsing', () {
    test('unknown state / source / season / kind fall back', () {
      final status = OpenStatusDto.fromJson({
        'state': 'OPENING_SOON_V2',
        'season': 'HAJJ',
        'spanSeason': 'HAJJ',
      });
      expect(status.state, OpenState.unknown);
      expect(status.season, HoursSeason.regular);
      expect(status.spanSeason, HoursSeason.regular);
      expect(status.closingSoon, isFalse);

      final day = DayScheduleDto.fromJson({
        'dayOfWeek': 3,
        'kind': 'SPLIT_SHIFT',
      });
      expect(day.kind, HoursDayKind.closed);
      expect(day.intervals, isEmpty);

      final scope = ScopeHoursDto.fromJson({
        'hoursSource': 'PLATFORM',
        'statusSource': 'PLATFORM',
        'status': {'state': 'UNKNOWN', 'openNow': null},
      });
      expect(scope.hoursSource, HoursSource.none);
      expect(scope.statusSource, HoursSource.venue);
      expect(scope.status.state, OpenState.unknown);
      expect(scope.status.openNow, isNull);
      expect(scope.today, isNull);
    });

    test('missing lists default to empty', () {
      final oh = VenueOpeningHoursDto.fromJson({
        'timezone': 'Asia/Baghdad',
        'evaluatedAt': '2026-09-28T21:40:00+03:00',
        'summary': {
          'hoursSource': 'NONE',
          'statusSource': 'VENUE',
          'status': {'state': 'UNKNOWN'},
        },
      });
      expect(oh.branches, isEmpty);
      expect(oh.variesByBranch, isFalse);

      final gallery = VenueGalleryDto.fromJson({});
      expect(gallery.totalCount, 0);
      expect(gallery.photos, isEmpty);
      expect(gallery.tagCounts, isEmpty);
    });
  });
}
