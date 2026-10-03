import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/domain/dto/response/business_response.dart';
import 'package:hangout/domain/dto/response/featured_collection_response.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/domain/dto/response/ghost_hangout_media_response.dart';
import 'package:hangout/domain/dto/response/ghost_post_media_response.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/domain/dto/response/intent_venues_response.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/domain/dto/response/public_event_media_response.dart';
import 'package:hangout/domain/dto/response/served_ad_response.dart';
import 'package:hangout/domain/dto/response/shake_recommendation_response.dart';
import 'package:hangout/domain/dto/response/trending_venue_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/domain/dto/response/weekly_recommendations_response.dart';

const _original = 'https://media.dlliny.com/posts/7f3a/clip.mp4';
const _stream =
    'https://video.dlliny.com/0b8e4c52-9f5e-4d3a-a1f0-6c2d7e9b1a44/playlist.m3u8';

typedef _Parsed = ({
  String? stream,
  String? original,
  Map<String, dynamic> json,
});

class _Carrier {
  const _Carrier(this.dto, this.key, this.originalKey, this.base, this.parse);

  final String dto;
  final String key;
  final String originalKey;
  final Map<String, dynamic> base;
  final _Parsed Function(Map<String, dynamic> json) parse;
}

Map<String, dynamic> _venueFixture() =>
    jsonDecode(
          File('test/fixtures/venue_response_v106.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

Map<String, dynamic> _memoryJson() => {
  'id': 'mem-1',
  'owner': {'type': 'USER', 'id': 'user-1', 'verified': false},
  'contentType': 'VIDEO',
  'mediaUrl': _original,
  'viewCount': 0,
  'uniqueViewerCount': 0,
  'viewedByMe': false,
  'mine': false,
  'reactions': {'total': 0, 'buckets': <Object>[]},
};

Map<String, dynamic> _summaryJson() => {
  'id': 'venue-1',
  'nameAr': 'مقهى',
  'nameEn': 'Cafe',
  'verified': false,
  'hasShisha': false,
  'hasParking': false,
  'coverUrl': _original,
};

final _carriers = <_Carrier>[
  _Carrier(
    'FeedMediaItem',
    'streamUrl',
    'url',
    {'type': 'video', 'url': _original},
    (j) {
      final m = FeedMediaItem.fromJson(j);
      return (stream: m.streamUrl, original: m.url, json: m.toJson());
    },
  ),
  _Carrier(
    'MediaItem',
    'streamUrl',
    'url',
    {'url': _original, 'mediaType': 'video', 'sortOrder': 0},
    (j) {
      final m = MediaItem.fromJson(j);
      return (stream: m.streamUrl, original: m.url, json: m.toJson());
    },
  ),
  _Carrier(
    'GhostPostMediaResponse',
    'streamUrl',
    'url',
    {
      'id': 'm-1',
      'postId': 'post-1',
      'url': _original,
      'mediaType': 'video',
      'sortOrder': 0,
      'createdAt': '2026-09-29T10:00:00Z',
    },
    (j) {
      final m = GhostPostMediaResponse.fromJson(j);
      return (stream: m.streamUrl, original: m.url, json: m.toJson());
    },
  ),
  _Carrier(
    'HangoutMediaResponse',
    'streamUrl',
    'url',
    {'id': 'm-1', 'url': _original, 'mediaType': 'video', 'sortOrder': 0},
    (j) {
      final m = HangoutMediaResponse.fromJson(j);
      return (stream: m.streamUrl, original: m.url, json: m.toJson());
    },
  ),
  _Carrier(
    'GhostHangoutMediaResponse',
    'streamUrl',
    'url',
    {
      'id': 'm-1',
      'hangoutId': 'hangout-1',
      'url': _original,
      'mediaType': 'video',
      'sortOrder': 0,
      'createdAt': '2026-09-29T10:00:00Z',
    },
    (j) {
      final m = GhostHangoutMediaResponse.fromJson(j);
      return (stream: m.streamUrl, original: m.url, json: m.toJson());
    },
  ),
  _Carrier('MemoryResponse', 'mediaStreamUrl', 'mediaUrl', _memoryJson(), (j) {
    final m = MemoryResponse.fromJson(j);
    return (stream: m.mediaStreamUrl, original: m.mediaUrl, json: m.toJson());
  }),
  _Carrier(
    'VenueResponse (V106 fixture)',
    'coverStreamUrl',
    'coverUrl',
    {..._venueFixture(), 'coverUrl': _original, 'coverMediaType': 'video'},
    (j) {
      final v = VenueResponse.fromJson(j);
      return (stream: v.coverStreamUrl, original: v.coverUrl, json: v.toJson());
    },
  ),
  _Carrier(
    'VenueSummaryResponse',
    'coverStreamUrl',
    'coverUrl',
    _summaryJson(),
    (j) {
      final v = VenueSummaryResponse.fromJson(j);
      return (stream: v.coverStreamUrl, original: v.coverUrl, json: v.toJson());
    },
  ),
  _Carrier(
    'BusinessVenueResponse',
    'coverStreamUrl',
    'coverUrl',
    {
      'venueId': 'venue-1',
      'nameAr': 'مقهى',
      'nameEn': 'Cafe',
      'verified': false,
      'active': true,
      'inheritStyle': true,
      'coverUrl': _original,
      'coverMediaType': 'video',
    },
    (j) {
      final v = BusinessVenueResponse.fromJson(j);
      return (stream: v.coverStreamUrl, original: v.coverUrl, json: v.toJson());
    },
  ),
  _Carrier(
    'TrendingVenueResponse',
    'coverStreamUrl',
    'coverUrl',
    {'venueId': 'venue-1', 'nameAr': 'مقهى', 'coverUrl': _original, 'score': 9},
    (j) {
      final v = TrendingVenueResponse.fromJson(j);
      return (stream: v.coverStreamUrl, original: v.coverUrl, json: v.toJson());
    },
  ),
  _Carrier(
    'WeeklyRecommendationItem',
    'coverStreamUrl',
    'coverUrl',
    {
      'venueId': 'venue-1',
      'nameAr': 'مقهى',
      'coverUrl': _original,
      'position': 0,
      'score': 1.5,
      'fallback': false,
    },
    (j) {
      final v = WeeklyRecommendationItem.fromJson(j);
      return (stream: v.coverStreamUrl, original: v.coverUrl, json: v.toJson());
    },
  ),
  _Carrier(
    'CollectionVenue',
    'coverStreamUrl',
    'coverUrl',
    {
      'venueId': 'venue-1',
      'nameAr': 'مقهى',
      'coverUrl': _original,
      'positionInCollection': 0,
    },
    (j) {
      final v = CollectionVenue.fromJson(j);
      return (stream: v.coverStreamUrl, original: v.coverUrl, json: v.toJson());
    },
  ),
  _Carrier(
    'ShakeRecommendationItem',
    'coverStreamUrl',
    'coverUrl',
    {'venueId': 'venue-1', 'nameAr': 'مقهى', 'coverUrl': _original},
    (j) {
      final v = ShakeRecommendationItem.fromJson(j);
      return (stream: v.coverStreamUrl, original: v.coverUrl, json: v.toJson());
    },
  ),
  _Carrier(
    'PublicEventMediaResponse',
    'streamUrl',
    'url',
    {'id': 'm-1', 'mediaType': 'video', 'url': _original},
    (j) {
      final m = PublicEventMediaResponse.fromJson(j);
      return (stream: m.streamUrl, original: m.url, json: m.toJson());
    },
  ),
  _Carrier(
    'ServedAdItem',
    'mediaStreamUrl',
    'mediaUrl',
    {
      'adId': 'ad-1',
      'placement': 'reels_placement',
      'sourceType': 'CUSTOM',
      'mediaUrl': _original,
      'mediaType': 'video',
    },
    (j) {
      final a = ServedAdItem.fromJson(j);
      return (stream: a.mediaStreamUrl, original: a.mediaUrl, json: a.toJson());
    },
  ),
  _Carrier(
    'CampaignCreativeResponse',
    'mediaStreamUrl',
    'mediaUrl',
    {
      'id': 'cr-1',
      'sourceType': 'CUSTOM',
      'mediaUrl': _original,
      'mediaType': 'video',
    },
    (j) {
      final c = CampaignCreativeResponse.fromJson(j);
      return (stream: c.mediaStreamUrl, original: c.mediaUrl, json: c.toJson());
    },
  ),
];

void main() {
  for (final carrier in _carriers) {
    group('${carrier.dto}.${carrier.key}', () {
      test('an older backend that omits the key parses to null', () {
        expect(carrier.base.containsKey(carrier.key), isFalse);

        final parsed = carrier.parse(carrier.base);

        expect(parsed.stream, isNull);
        expect(parsed.original, _original);
      });

      test('an explicit null (stream still encoding) parses to null', () {
        final parsed = carrier.parse({...carrier.base, carrier.key: null});

        expect(parsed.stream, isNull);
        expect(parsed.original, _original);
      });

      test('a ready stream is read without touching the original', () {
        final parsed = carrier.parse({...carrier.base, carrier.key: _stream});

        expect(parsed.stream, _stream);
        expect(parsed.original, _original);
        expect(parsed.json[carrier.key], _stream);
        expect(parsed.json[carrier.originalKey], _original);
      });
    });
  }

  group('streams survive the envelopes the app actually receives', () {
    Map<String, dynamic> media({String? streamUrl}) => {
      'type': 'video',
      'url': _original,
      'streamUrl': ?streamUrl,
    };

    test('feed / reels posts carry it per media item', () {
      final post = PostFeedItem.fromJson({
        'id': 'post-1',
        'likesCount': 0,
        'commentsCount': 0,
        'mediaUrls': [media(streamUrl: _stream), media()],
        'createdAt': '2026-09-29T10:00:00Z',
      });

      expect(post.mediaUrls.map((m) => m.streamUrl), [_stream, null]);
      expect(post.mediaUrls.map((m) => m.url), [_original, _original]);
    });

    test('feed hangouts carry it per media item', () {
      final hangout = HangoutFeedItem.fromJson({
        'id': 'hangout-1',
        'scheduledAt': '2026-10-01T18:00:00Z',
        'status': 'confirmed',
        'attendees': <Object>[],
        'likesCount': 0,
        'commentsCount': 0,
        'joinPolicy': 'OPEN',
        'postVisibility': 'PUBLIC',
        'media': [media(streamUrl: _stream)],
        'createdAt': '2026-09-29T10:00:00Z',
      });

      expect(hangout.media.single.streamUrl, _stream);
    });

    test('post details carry it per media item', () {
      final post = PostResponse.fromJson({
        'id': 'post-1',
        'likesCount': 0,
        'commentsCount': 0,
        'likedByMe': false,
        'mine': false,
        'media': [
          {
            'url': _original,
            'mediaType': 'video',
            'sortOrder': 0,
            'streamUrl': _stream,
          },
        ],
        'userMentions': <Object>[],
        'venueMentions': <Object>[],
        'createdAt': '2026-09-29T10:00:00Z',
      });

      expect(post.media.single.streamUrl, _stream);
    });

    test('the memory tray carries it per memory', () {
      final bucket = MemoryTrayBucket.fromJson({
        'owner': {'type': 'USER', 'id': 'user-1', 'verified': false},
        'memories': [
          {..._memoryJson(), 'mediaStreamUrl': _stream},
          _memoryJson(),
        ],
        'hasUnwatched': true,
      });

      expect(bucket.memories.map((m) => m.mediaStreamUrl), [_stream, null]);
    });

    test('intent venues (paged summaries) carry the cover stream', () {
      final res = IntentVenuesResponse.fromJson({
        'hasNoMatches': false,
        'venues': {
          'content': [
            {..._summaryJson(), 'coverStreamUrl': _stream},
          ],
          'number': 0,
          'size': 20,
          'totalElements': 1,
          'totalPages': 1,
          'last': true,
        },
      });

      expect(res.venues.content.single.coverStreamUrl, _stream);
    });

    test('featured collections carry the cover stream per venue', () {
      final col = FeaturedCollectionResponse.fromJson({
        'id': 'col-1',
        'titleAr': 'سهرات',
        'titleEn': 'Nights',
        'startsAt': '2026-09-01T00:00:00Z',
        'endsAt': '2026-10-01T00:00:00Z',
        'position': 0,
        'createdByAdminId': 'admin-1',
        'createdAt': '2026-09-01T00:00:00Z',
        'updatedAt': '2026-09-01T00:00:00Z',
        'venues': [
          {
            'venueId': 'venue-1',
            'nameAr': 'مقهى',
            'coverUrl': _original,
            'coverStreamUrl': _stream,
            'positionInCollection': 0,
          },
        ],
      });

      expect(col.venues.single.coverStreamUrl, _stream);
    });

    test('the unmodified V106 venue fixture has no stream', () {
      final venue = VenueResponse.fromJson(_venueFixture());

      expect(venue.coverStreamUrl, isNull);
    });
  });
}
