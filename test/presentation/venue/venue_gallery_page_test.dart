import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/venue/pages/venue_gallery_page.dart';
import 'package:hangout/presentation/venue/pages/venue_photo_viewer_page.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_photo_image.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gallery_test_helper.dart';
import '../../helpers/locale_test_helper.dart';
import '../../helpers/test_harness.dart';

void main() {
  late MockApiService api;

  final photos = [
    buildGalleryPhoto('wide-1', tags: ['inside', 'seating']),
    buildGalleryPhoto('wide-2', tags: ['inside', 'hookah_lounge']),
    buildGalleryPhoto('karrada', tags: ['outside'], locationId: 'b-karrada'),
    buildGalleryPhoto('mansour', tags: ['view'], locationId: 'b-mansour'),
  ];
  final branches = [
    buildBranch('b-karrada', labelAr: 'الكرادة', isPrimary: true),
    buildBranch('b-mansour', districtNameAr: 'المنصور', sortOrder: 1),
  ];

  setUpAll(() => loadTestLocale('ar'));

  setUp(() async {
    await resetLocator();
    api = MockApiService();
    putSingleton<ApiService>(api);
    when(
      () => api.listVenueGallery(
        any(),
        tag: any(named: 'tag'),
        locationId: any(named: 'locationId'),
      ),
    ).thenAnswer((_) async => apiOk(photos));
  });

  tearDown(resetLocator);

  Future<void> pump(
    WidgetTester tester, {
    VenueResponse? venue,
    String? tag,
    GalleryImageProviderBuilder? images,
  }) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      galleryHost(
        VenueGalleryPage(
          venue:
              venue ?? buildGalleryVenue(photos: photos, locations: branches),
          initialTag: tag,
        ),
        scrollable: false,
        images: images,
      ),
    );
    await tester.pump();
  }

  List<String> gridIds(WidgetTester tester) => [
    for (final t in tester.widgetList<GalleryPhotoTile>(
      find.byType(GalleryPhotoTile),
    ))
      t.photo.id,
  ];

  testWidgets('a 3-column grid of 3:4 tiles', (tester) async {
    await pump(tester);
    expect(gridIds(tester), ['wide-1', 'wide-2', 'karrada', 'mansour']);
    final first = tester.getRect(find.byType(GalleryPhotoTile).at(0));
    final second = tester.getRect(find.byType(GalleryPhotoTile).at(1));
    expect(first.width / first.height, closeTo(0.75, 0.001));
    expect(first.width, closeTo((390 - 4) / 3, 0.01));
    expect(first.left, greaterThan(second.left));
  });

  testWidgets('tag chips: «الكل» plus the known tags present, with counts', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('الكل (4)'), findsOneWidget);
    expect(find.text('من الداخل (2)'), findsOneWidget);
    expect(find.text('الجلسات الخارجية (1)'), findsOneWidget);
    expect(find.text('الجلسات (1)'), findsOneWidget);
    expect(find.text('الإطلالة (1)'), findsOneWidget);
    expect(find.textContaining('hookah'), findsNothing);
    expect(find.textContaining('venue.gallery'), findsNothing);
    expect(find.textContaining('قسم العوائل'), findsNothing);

    await tester.tap(find.text('من الداخل (2)'));
    await tester.pump();
    expect(gridIds(tester), ['wide-1', 'wide-2']);

    await tester.tap(find.text('الكل (4)'));
    await tester.pump();
    expect(gridIds(tester), hasLength(4));
  });

  testWidgets('opens pre-filtered from a preview chip', (tester) async {
    await pump(tester, tag: 'outside');
    expect(gridIds(tester), ['karrada']);
  });

  testWidgets('branch filter: that branch plus the venue-wide photos', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('كل الفروع'), findsOneWidget);
    expect(find.text('الكرادة'), findsOneWidget);
    expect(find.text('المنصور'), findsOneWidget);

    await tester.tap(find.text('المنصور'));
    await tester.pump();
    expect(gridIds(tester), ['wide-1', 'wide-2', 'mansour']);
    expect(find.text('الكل (3)'), findsOneWidget);
    expect(find.textContaining('الجلسات الخارجية'), findsNothing);

    await tester.tap(find.text('كل الفروع'));
    await tester.pump();
    expect(gridIds(tester), hasLength(4));
  });

  testWidgets('branch and tag filters combine; a tag the new branch lacks '
      'resets to «الكل», one it has is kept', (tester) async {
    await pump(tester);
    await tester.tap(find.text('الكرادة'));
    await tester.pump();
    final outside = find.text('الجلسات الخارجية (1)');
    await tester.ensureVisible(outside);
    await tester.tap(outside);
    await tester.pump();
    expect(gridIds(tester), ['karrada']);

    await tester.tap(find.text('المنصور'));
    await tester.pump();
    expect(gridIds(tester), ['wide-1', 'wide-2', 'mansour']);
    expect(find.textContaining('الجلسات الخارجية'), findsNothing);

    final inside = find.text('من الداخل (2)');
    await tester.ensureVisible(inside);
    await tester.tap(inside);
    await tester.pump();
    await tester.tap(find.text('الكرادة'));
    await tester.pump();
    expect(gridIds(tester), ['wide-1', 'wide-2']);
  });

  testWidgets('tiles are labelled with their tags and their place in the '
      'FILTERED list', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await tester.tap(find.text('من الداخل (2)'));
    await tester.pump();
    expect(
      tester.getSemantics(find.byType(GalleryPhotoTile).at(1)),
      isSemantics(
        label: 'من الداخل · 2 من 2',
        isButton: true,
        hasTapAction: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a landscape photo decodes wide enough to COVER its 3:4 '
      'tile (not blurred up from the tile width)', (tester) async {
    final widths = <String, int?>{};
    final solid = solidGalleryImages();
    await pump(
      tester,
      venue: buildGalleryVenue(
        photos: [
          buildGalleryPhoto('landscape', width: 2048, height: 1536),
          buildGalleryPhoto('portrait'),
        ],
      ),
      images: (url, {cacheWidth}) {
        widths[url.split('/').last] = cacheWidth;
        return solid(url, cacheWidth: cacheWidth);
      },
    );
    final tile = tester.getSize(find.byType(GalleryPhotoTile).first);
    const dpr = 3.0;
    expect(tile.width / tile.height, closeTo(0.75, 0.001));
    expect(
      widths['landscape.webp'],
      greaterThanOrEqualTo(tile.height * 4 / 3 * dpr),
    );
    expect(widths['portrait.webp'], (tile.width * dpr).ceil());
  });

  testWidgets('no branch row for a single-branch venue', (tester) async {
    await pump(
      tester,
      venue: buildGalleryVenue(photos: photos, locations: [branches.first]),
    );
    expect(find.text('كل الفروع'), findsNothing);
  });

  testWidgets('a tile opens the viewer on the FILTERED list', (tester) async {
    await pump(tester);
    await tester.tap(find.text('من الداخل (2)'));
    await tester.pump();
    await tester.tap(find.byType(GalleryPhotoTile).at(1));
    await tester.pumpAndSettle();
    final viewer = tester.widget<VenuePhotoViewerPage>(
      find.byType(VenuePhotoViewerPage),
    );
    expect(viewer.photos.map((p) => p.id), ['wide-1', 'wide-2']);
    expect(viewer.initialIndex, 1);
  });

  testWidgets('an empty embedded gallery loads from the endpoint', (
    tester,
  ) async {
    await pump(tester, venue: buildGalleryVenue(withGallery: false));
    await tester.pump();
    expect(gridIds(tester), hasLength(4));
  });

  testWidgets('a failed first load offers a retry', (tester) async {
    when(
      () => api.listVenueGallery(
        any(),
        tag: any(named: 'tag'),
        locationId: any(named: 'locationId'),
      ),
    ).thenThrow(dioTimeout());
    await pump(tester, venue: buildGalleryVenue(withGallery: false));
    await tester.pump();
    expect(find.text('إعادة المحاولة'), findsOneWidget);

    when(
      () => api.listVenueGallery(
        any(),
        tag: any(named: 'tag'),
        locationId: any(named: 'locationId'),
      ),
    ).thenAnswer((_) async => apiOk(<GalleryPhotoDto>[photos.first]));
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();
    await tester.pump();
    expect(gridIds(tester), ['wide-1']);
  });
}
