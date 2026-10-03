import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/presentation/venue/controllers/venue_gallery/venue_gallery_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gallery_test_helper.dart';
import '../../helpers/test_harness.dart';

Future<void> _settle() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late MockApiService api;

  final wide = buildGalleryPhoto('wide', tags: ['inside']);
  final karrada = buildGalleryPhoto(
    'karrada',
    tags: ['outside'],
    locationId: 'b-karrada',
  );
  final mansour = buildGalleryPhoto(
    'mansour',
    tags: ['view'],
    locationId: 'b-mansour',
  );

  void answerList(Future<List<GalleryPhotoDto>> Function() photos) {
    when(
      () => api.listVenueGallery(
        kGalleryVenueId,
        tag: any(named: 'tag'),
        locationId: any(named: 'locationId'),
      ),
    ).thenAnswer((_) async => apiOk(await photos()));
  }

  setUp(() async {
    await resetLocator();
    api = MockApiService();
    putSingleton<ApiService>(api);
  });

  tearDown(resetLocator);

  test('paints the embedded photos at once, then refreshes the whole list '
      '(filters stay client-side)', () async {
    answerList(() async => [wide, karrada, mansour]);
    final bloc = VenueGalleryBloc(venueId: kGalleryVenueId, seed: [wide]);
    expect(bloc.state.status, VenueGalleryStatus.ready);
    expect(bloc.state.visible, [wide]);

    bloc.add(const VenueGalleryRequested());
    await _settle();
    expect(bloc.state.photos.map((p) => p.id), ['wide', 'karrada', 'mansour']);
    verify(() => api.listVenueGallery(kGalleryVenueId)).called(1);
    await bloc.close();
  });

  test('a failed refresh keeps the embedded photos', () async {
    when(
      () => api.listVenueGallery(
        any(),
        tag: any(named: 'tag'),
        locationId: any(named: 'locationId'),
      ),
    ).thenThrow(dioTimeout());
    final bloc = VenueGalleryBloc(venueId: kGalleryVenueId, seed: [wide])
      ..add(const VenueGalleryRequested());
    await _settle();
    expect(bloc.state.status, VenueGalleryStatus.ready);
    expect(bloc.state.photos, [wide]);
    await bloc.close();
  });

  test('without embedded photos a failure is an error state', () async {
    when(
      () => api.listVenueGallery(
        any(),
        tag: any(named: 'tag'),
        locationId: any(named: 'locationId'),
      ),
    ).thenAnswer((_) async => apiFail(error: 'Venue not found'));
    final bloc = VenueGalleryBloc(venueId: kGalleryVenueId)
      ..add(const VenueGalleryRequested());
    expect(bloc.state.status, VenueGalleryStatus.loading);
    await _settle();
    expect(bloc.state.status, VenueGalleryStatus.error);
    await bloc.close();
  });

  test(
    'branch filter = that branch + venue-wide; tag filter within it',
    () async {
      final bloc = VenueGalleryBloc(
        venueId: kGalleryVenueId,
        seed: [wide, karrada, mansour],
      );
      bloc.add(const VenueGalleryBranchSelected('b-karrada'));
      await _settle();
      expect(bloc.state.visible.map((p) => p.id), ['wide', 'karrada']);
      expect(bloc.state.tagCounts, {'inside': 1, 'outside': 1});

      bloc.add(const VenueGalleryTagSelected('outside'));
      await _settle();
      expect(bloc.state.visible.map((p) => p.id), ['karrada']);

      bloc.add(const VenueGalleryBranchSelected('b-mansour'));
      await _settle();
      expect(bloc.state.tag, isNull);
      expect(bloc.state.visible.map((p) => p.id), ['wide', 'mansour']);

      bloc.add(const VenueGalleryTagSelected('inside'));
      bloc.add(const VenueGalleryBranchSelected(null));
      await _settle();
      expect(bloc.state.tag, 'inside');
      expect(bloc.state.visible.map((p) => p.id), ['wide']);
      await bloc.close();
    },
  );
}
