import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_harness.dart';

VenueResponse _venue({String id = 'venue-1'}) => VenueResponse(
  id: id,
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
  hours: const [],
  mediaUrls: const [],
);

void main() {
  late MockApiService api;

  setUp(() async {
    api = MockApiService();
    await resetLocator();
    putSingleton<ApiService>(api);
  });

  tearDown(resetLocator);

  group('GetVenueDetails', () {
    blocTest<VenueBloc, VenueState>(
      'emits [Loading, Loaded] on success',
      setUp: () => when(
        () => api.getVenue('venue-1'),
      ).thenAnswer((_) async => apiOk(_venue())),
      build: VenueBloc.new,
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => [
        isA<GetVenueDetailsLoading>(),
        isA<GetVenueDetailsLoaded>().having((s) => s.venue.id, 'id', 'venue-1'),
      ],
    );

    blocTest<VenueBloc, VenueState>(
      'a server error surfaces its message, once',
      setUp: () => when(
        () => api.getVenue('venue-1'),
      ).thenThrow(dioErrorWithMessage('Venue not found', statusCode: 404)),
      build: VenueBloc.new,
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => [
        isA<GetVenueDetailsLoading>(),
        isA<GetVenueDetailsError>().having(
          (s) => s.message,
          'message',
          'Venue not found',
        ),
      ],
    );

    blocTest<VenueBloc, VenueState>(
      'a network failure without a body emits an error',
      setUp: () =>
          when(() => api.getVenue('venue-1')).thenThrow(dioErrorWithoutBody()),
      build: VenueBloc.new,
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => [
        isA<GetVenueDetailsLoading>(),
        isA<GetVenueDetailsError>(),
      ],
    );

    blocTest<VenueBloc, VenueState>(
      'a payload this build cannot parse (non-Dio) emits an error, not a hang',
      setUp: () => when(() => api.getVenue('venue-1')).thenAnswer(
        (_) async => throw TypeError(),
      ),
      build: VenueBloc.new,
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => [
        isA<GetVenueDetailsLoading>(),
        isA<GetVenueDetailsError>(),
      ],
    );

    blocTest<VenueBloc, VenueState>(
      'success=false with no data emits the server message',
      setUp: () => when(
        () => api.getVenue('venue-1'),
      ).thenAnswer((_) async => apiFail<VenueResponse>(error: 'boom')),
      build: VenueBloc.new,
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => [
        isA<GetVenueDetailsLoading>(),
        isA<GetVenueDetailsError>().having((s) => s.message, 'message', 'boom'),
      ],
    );

    blocTest<VenueBloc, VenueState>(
      'retry from the error state shows loading again, then the venue',
      setUp: () => when(
        () => api.getVenue('venue-1'),
      ).thenAnswer((_) async => apiOk(_venue())),
      build: VenueBloc.new,
      seed: () => GetVenueDetailsError('earlier failure'),
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => [
        isA<GetVenueDetailsLoading>(),
        isA<GetVenueDetailsLoaded>(),
      ],
    );

    blocTest<VenueBloc, VenueState>(
      'refreshing a loaded venue keeps it on screen (no loading flash)',
      setUp: () => when(
        () => api.getVenue('venue-1'),
      ).thenAnswer((_) async => apiOk(_venue())),
      build: VenueBloc.new,
      seed: () => GetVenueDetailsLoaded(_venue()),
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => [isA<GetVenueDetailsLoaded>()],
    );

    blocTest<VenueBloc, VenueState>(
      'a failed refresh (network) keeps the loaded venue on screen',
      setUp: () =>
          when(() => api.getVenue('venue-1')).thenThrow(dioErrorWithoutBody()),
      build: VenueBloc.new,
      seed: () => GetVenueDetailsLoaded(_venue()),
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => <VenueState>[],
      verify: (bloc) => expect(
        bloc.state,
        isA<GetVenueDetailsLoaded>().having((s) => s.venue.id, 'id', 'venue-1'),
      ),
    );

    blocTest<VenueBloc, VenueState>(
      'a failed refresh (unparseable payload) keeps the loaded venue on screen',
      setUp: () => when(
        () => api.getVenue('venue-1'),
      ).thenAnswer((_) async => throw TypeError()),
      build: VenueBloc.new,
      seed: () => GetVenueDetailsLoaded(_venue()),
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => <VenueState>[],
    );

    blocTest<VenueBloc, VenueState>(
      'a failed refresh (success=false) keeps the loaded venue on screen',
      setUp: () => when(
        () => api.getVenue('venue-1'),
      ).thenAnswer((_) async => apiFail<VenueResponse>(error: 'boom')),
      build: VenueBloc.new,
      seed: () => GetVenueDetailsLoaded(_venue()),
      act: (bloc) => bloc.add(GetVenueDetails('venue-1')),
      expect: () => <VenueState>[],
    );
  });
}
