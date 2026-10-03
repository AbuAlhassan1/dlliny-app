import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/hangout/bloc/hangout_details_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_harness.dart';

const _media = HangoutMediaResponse(
  id: 'm1',
  url: 'https://cdn/m1.jpg',
  mediaType: 'image',
  sortOrder: 0,
);

VenueResponse _venue() => const VenueResponse(
  id: 'venue-1',
  nameAr: 'مقهى',
  nameEn: 'Cafe',
  avgRating: 0,
  totalRatings: 0,
  followerCount: 0,
  verified: false,
  family: false,
  hasShisha: false,
  hasParking: false,
  hasWifi: false,
  hasOutdoor: false,
  hasPrivateRoom: false,
  hours: [],
  mediaUrls: [],
);

void main() {
  late MockApiService api;

  setUp(() async {
    api = MockApiService();
    await resetLocator();
    putSingleton<ApiService>(api);
  });

  tearDown(resetLocator);

  blocTest<HangoutDetailsBloc, HangoutDetailsState>(
    'a venue payload that fails to parse still loads the hangout and its media',
    setUp: () {
      when(
        () => api.getHangout('h1'),
      ).thenAnswer((_) async => apiOk(buildHangout(id: 'h1')));
      when(
        () => api.getHangoutMedia('h1'),
      ).thenAnswer((_) async => apiOk([_media]));
      when(
        () => api.getVenue('venue-1'),
      ).thenAnswer((_) async => throw TypeError());
    },
    build: HangoutDetailsBloc.new,
    act: (bloc) => bloc.add(LoadHangoutDetails('h1')),
    expect: () => [
      isA<HangoutDetailsLoading>(),
      isA<HangoutDetailsLoaded>()
          .having((s) => s.venue, 'venue', isNull)
          .having((s) => s.media, 'media', hasLength(1)),
    ],
  );

  blocTest<HangoutDetailsBloc, HangoutDetailsState>(
    'a media failure does not discard the venue',
    setUp: () {
      when(
        () => api.getHangout('h1'),
      ).thenAnswer((_) async => apiOk(buildHangout(id: 'h1')));
      when(() => api.getHangoutMedia('h1')).thenThrow(dioErrorWithoutBody());
      when(
        () => api.getVenue('venue-1'),
      ).thenAnswer((_) async => apiOk(_venue()));
    },
    build: HangoutDetailsBloc.new,
    act: (bloc) => bloc.add(LoadHangoutDetails('h1')),
    expect: () => [
      isA<HangoutDetailsLoading>(),
      isA<HangoutDetailsLoaded>()
          .having((s) => s.venue?.id, 'venue', 'venue-1')
          .having((s) => s.media, 'media', isEmpty),
    ],
  );

  blocTest<HangoutDetailsBloc, HangoutDetailsState>(
    'a hangout payload that fails to parse emits an error (the page offers retry)',
    setUp: () => when(
      () => api.getHangout('h1'),
    ).thenAnswer((_) async => throw TypeError()),
    build: HangoutDetailsBloc.new,
    act: (bloc) => bloc.add(LoadHangoutDetails('h1')),
    expect: () => [isA<HangoutDetailsLoading>(), isA<HangoutDetailsError>()],
  );
}
