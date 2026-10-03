import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/business_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/pages/venue_gallery_manager_page.dart';
import 'package:hangout/presentation/venue/pages/venue_gallery_page.dart';
import 'package:hangout/presentation/venue/pages/venue_photo_viewer_page.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_photo_image.dart';
import 'package:hangout/presentation/venue/widgets/gallery/venue_gallery_preview.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gallery_test_helper.dart';
import '../../helpers/locale_test_helper.dart';
import '../../helpers/test_harness.dart';

class _FakeVenueBloc extends MockBloc<VenueEvent, VenueState>
    implements VenueBloc {}

List<GalleryPhotoDto> _photos(int n) => [
  for (var i = 0; i < n; i++)
    buildGalleryPhoto(
      'p$i',
      width: i.isEven ? 1536 : 2048,
      height: i.isEven ? 2048 : 1536,
      tags: i == 0 ? ['inside', 'seating'] : ['inside'],
      placeholderHash: kSampleThumbHash,
    ),
];

void main() {
  late _FakeVenueBloc venueBloc;
  late MockApiService api;

  setUpAll(() => loadTestLocale('ar'));

  setUp(() async {
    await resetLocator();
    api = MockApiService();
    putSingleton<ApiService>(api);
    when(() => api.businessListGallery(any())).thenAnswer(
      (_) async =>
          apiOk(const BusinessGalleryResponse(maxPhotos: 24, remaining: 24)),
    );
    when(
      () => api.listVenueGallery(
        any(),
        tag: any(named: 'tag'),
        locationId: any(named: 'locationId'),
      ),
    ).thenAnswer((_) async => apiOk(<GalleryPhotoDto>[]));
    venueBloc = _FakeVenueBloc();
    when(() => venueBloc.state).thenReturn(VenueInitial());
  });

  tearDown(resetLocator);

  Future<void> pump(
    WidgetTester tester,
    List<GalleryPhotoDto> photos, {
    List<String> perms = const [],
    Map<String, int>? tagCounts,
    bool withGallery = true,
    GalleryImageProviderBuilder? images,
  }) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      galleryHost(
        VenueGalleryPreview(
          venue: buildGalleryVenue(
            photos: photos,
            tagCounts: tagCounts,
            withGallery: withGallery,
          ),
        ),
        perms: perms,
        venueBloc: venueBloc,
        images: images,
      ),
    );
  }

  Finder tiles() => find.byType(GalleryPhotoTile);

  group('0 photos', () {
    testWidgets('visitors see nothing (also without the V106 field)', (
      tester,
    ) async {
      await pump(tester, const []);
      expect(find.text('صور المكان'), findsNothing);
      expect(tester.getSize(find.byType(VenueGalleryPreview)).height, 0);

      await pump(tester, const [], withGallery: false);
      expect(tester.getSize(find.byType(VenueGalleryPreview)).height, 0);
    });

    testWidgets('a pre-V106 venue (no gallery field) shows nothing, even to '
        'owners', (tester) async {
      await pump(
        tester,
        const [],
        withGallery: false,
        perms: const [VenuePerm.mediaUpload, VenuePerm.mediaDelete],
      );
      expect(tester.getSize(find.byType(VenueGalleryPreview)).height, 0);
    });

    testWidgets('a media-upload holder gets the dashed call to action', (
      tester,
    ) async {
      await pump(tester, const [], perms: const [VenuePerm.mediaUpload]);
      expect(find.text('أضف صوراً لديكور مكانك وأجوائه'), findsOneWidget);
      expect(find.text('إدارة الصور'), findsNothing);

      await tester.tap(find.text('أضف صوراً لديكور مكانك وأجوائه'));
      await tester.pumpAndSettle();
      expect(find.byType(VenueGalleryManagerPage), findsOneWidget);
    });
  });

  testWidgets('1 photo: one tile across the width, no mosaic', (tester) async {
    await pump(tester, _photos(1));
    expect(tiles(), findsOneWidget);
    expect(find.text('عرض كل الصور (1)'), findsOneWidget);
    final size = tester.getSize(tiles());
    expect(size.width, 360);
    expect(size.height, 360);
  });

  testWidgets('2 photos: one row at a shared height from width/height', (
    tester,
  ) async {
    await pump(tester, _photos(2));
    expect(tiles(), findsNWidgets(2));
    final a = tester.getSize(tiles().at(0));
    final b = tester.getSize(tiles().at(1));
    expect(a.height, b.height);
    expect(a.width + b.width + 4, closeTo(360, 0.01));
    expect(a.width / a.height, closeTo(0.75, 0.01));
    expect(b.width / b.height, closeTo(4 / 3, 0.01));
  });

  testWidgets('3 photos: large 3:4 tile on the start side, two stacked, '
      'no «+N»', (tester) async {
    await pump(tester, _photos(3));
    expect(tiles(), findsNWidgets(3));
    expect(find.textContaining('+'), findsNothing);

    final big = tester.getRect(tiles().at(0));
    final small1 = tester.getRect(tiles().at(1));
    final small2 = tester.getRect(tiles().at(2));
    expect(big.width, closeTo((360 - 4) * 2 / 3, 0.01));
    expect(big.height, closeTo(big.width * 4 / 3, 0.01));
    expect(big.left, greaterThan(small1.left));
    expect(small1.left, small2.left);
    expect(small2.bottom, closeTo(big.bottom, 0.01));
  });

  testWidgets('7 photos: the last tile shows «+4» and opens the grid', (
    tester,
  ) async {
    await pump(tester, _photos(7));
    expect(tiles(), findsNWidgets(3));
    expect(find.text('+4'), findsOneWidget);
    expect(find.text('عرض كل الصور (7)'), findsOneWidget);

    await tester.tap(tiles().at(2));
    await tester.pumpAndSettle();
    expect(find.byType(VenueGalleryPage), findsOneWidget);
  });

  testWidgets('6 photos: the mosaic, «+3» on the last tile', (tester) async {
    await pump(tester, _photos(6));
    expect(tiles(), findsNWidgets(3));
    expect(find.text('+3'), findsOneWidget);
    expect(find.text('عرض كل الصور (6)'), findsOneWidget);
  });

  testWidgets('24 photos (the cap): «+21»', (tester) async {
    await pump(tester, _photos(24));
    expect(tiles(), findsNWidgets(3));
    expect(find.text('+21'), findsOneWidget);
    expect(find.text('عرض كل الصور (24)'), findsOneWidget);
  });

  testWidgets('«عرض كل الصور (N)» is a 48 dp target and opens the grid', (
    tester,
  ) async {
    await pump(tester, _photos(3));
    final seeAll = find.ancestor(
      of: find.text('عرض كل الصور (3)'),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(seeAll).height, greaterThanOrEqualTo(48));
    await tester.tap(find.text('عرض كل الصور (3)'));
    await tester.pumpAndSettle();
    expect(find.byType(VenueGalleryPage), findsOneWidget);
    expect(
      tester.widget<VenueGalleryPage>(find.byType(VenueGalleryPage)).initialTag,
      isNull,
    );
  });

  testWidgets('a landscape photo in the large 3:4 tile decodes wide enough '
      'to cover it', (tester) async {
    final widths = <String, int?>{};
    final solid = solidGalleryImages();
    await pump(
      tester,
      [
        buildGalleryPhoto('landscape', width: 2048, height: 1536),
        ..._photos(3).skip(1),
      ],
      images: (url, {cacheWidth}) {
        widths[url.split('/').last] = cacheWidth;
        return solid(url, cacheWidth: cacheWidth);
      },
    );
    final big = tester.getSize(tiles().at(0));
    expect(big.width / big.height, closeTo(0.75, 0.001));
    expect(
      widths['landscape.webp'],
      greaterThanOrEqualTo(big.height * 4 / 3 * 3),
    );
  });

  testWidgets('tiles are labelled buttons; the «+N» tile says it opens '
      'every photo', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, _photos(7));
    expect(
      tester.getSemantics(tiles().at(0)),
      isSemantics(
        label: 'من الداخل، الجلسات · 1 من 7',
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(tiles().at(2)),
      isSemantics(
        label: 'عرض كل الصور (7)',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('the layout is final before any image has loaded', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      galleryHost(
        VenueGalleryPreview(venue: buildGalleryVenue(photos: _photos(6))),
        venueBloc: venueBloc,
        images: (url, {cacheWidth}) => const _NeverImage(),
      ),
    );
    final before = tester.getSize(find.byType(VenueGalleryPreview));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getSize(find.byType(VenueGalleryPreview)), before);
    expect(before.height, greaterThan(300));
  });

  testWidgets('tapping a tile opens the viewer on that photo', (tester) async {
    await pump(tester, _photos(3));
    await tester.tap(tiles().at(1));
    await tester.pumpAndSettle();
    final viewer = tester.widget<VenuePhotoViewerPage>(
      find.byType(VenuePhotoViewerPage),
    );
    expect(viewer.initialIndex, 1);
    expect(viewer.photos, hasLength(3));
    expect(find.text('2 من 3'), findsOneWidget);
  });

  testWidgets('tag chips: known codes only, and each opens the grid '
      'pre-filtered', (tester) async {
    await pump(
      tester,
      _photos(3),
      tagCounts: const {'inside': 3, 'hookah_lounge': 2, 'seating': 1},
    );
    expect(find.text('من الداخل (3)'), findsOneWidget);
    expect(find.text('الجلسات (1)'), findsOneWidget);
    expect(find.textContaining('hookah'), findsNothing);
    expect(find.textContaining('venue.gallery.tags'), findsNothing);

    await tester.tap(find.text('الجلسات (1)'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<VenueGalleryPage>(find.byType(VenueGalleryPage)).initialTag,
      'seating',
    );
  });

  group('«إدارة الصور»', () {
    testWidgets('hidden from visitors', (tester) async {
      await pump(tester, _photos(3));
      expect(find.text('إدارة الصور'), findsNothing);
    });

    testWidgets('shown to staff (media upload without venue:update)', (
      tester,
    ) async {
      await pump(
        tester,
        _photos(3),
        perms: const ['venue:read', VenuePerm.mediaUpload],
      );
      expect(find.text('إدارة الصور'), findsOneWidget);
      await tester.ensureVisible(find.text('إدارة الصور'));
      await tester.tap(find.text('إدارة الصور'));
      await tester.pumpAndSettle();
      expect(find.byType(VenueGalleryManagerPage), findsOneWidget);
    });
  });
}

class _NeverImage extends ImageProvider<_NeverImage> {
  const _NeverImage();

  @override
  Future<_NeverImage> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(
    _NeverImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(Completer<ImageInfo>().future);
}
