import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/presentation/venue/pages/venue_photo_viewer_page.dart';

import '../../helpers/gallery_test_helper.dart';
import '../../helpers/locale_test_helper.dart';
import '../../helpers/test_harness.dart';

void main() {
  setUpAll(() => loadTestLocale('ar'));

  setUp(() async {
    await resetLocator();
    putSingleton<ApiService>(MockApiService());
  });

  tearDown(resetLocator);

  final photos = [
    buildGalleryPhoto('a', tags: ['inside']),
    buildGalleryPhoto(
      'b',
      width: 2048,
      height: 1536,
      tags: ['family_section', 'hookah_lounge'],
      locationId: 'b-karrada',
    ),
    buildGalleryPhoto('c'),
  ];

  Future<void> pump(WidgetTester tester, {int index = 0}) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      galleryHost(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => VenuePhotoViewerPage.open(
                  context,
                  photos: photos,
                  index: index,
                  branches: [buildBranch('b-karrada', labelAr: 'الكرادة')],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        scrollable: false,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  PageView pageView(WidgetTester tester) =>
      tester.widget<PageView>(find.byType(PageView));

  TransformationController visibleTransform(WidgetTester tester) => tester
      .widget<InteractiveViewer>(find.byType(InteractiveViewer).hitTestable())
      .transformationController!;

  testWidgets('counter, known tags and the branch label of the photo', (
    tester,
  ) async {
    await pump(tester, index: 1);
    expect(find.text('2 من 3'), findsOneWidget);
    expect(find.text('قسم العوائل'), findsOneWidget);
    expect(find.textContaining('hookah'), findsNothing);
    expect(find.text('الكرادة'), findsOneWidget);
  });

  testWidgets('swipes between photos; RTL: the next one comes from the left', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('1 من 3'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2 من 3'), findsOneWidget);
  });

  testWidgets('page swipe and swipe-to-close are off while zoomed', (
    tester,
  ) async {
    await pump(tester);
    expect(pageView(tester).physics, isA<PageScrollPhysics>());
    expect(
      tester.widget<DismissiblePage>(find.byType(DismissiblePage)).disabled,
      isFalse,
    );

    visibleTransform(tester).value = Matrix4.diagonal3Values(2, 2, 1);
    await tester.pump();
    expect(pageView(tester).physics, isA<NeverScrollableScrollPhysics>());
    expect(
      tester.widget<DismissiblePage>(find.byType(DismissiblePage)).disabled,
      isTrue,
    );

    await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('1 من 3'), findsOneWidget);

    visibleTransform(tester).value = Matrix4.identity();
    await tester.pump();
    expect(pageView(tester).physics, isA<PageScrollPhysics>());
    expect(find.text('1 من 3'), findsOneWidget, reason: 'position kept');
  });

  testWidgets('double tap zooms to 2× and back', (tester) async {
    await pump(tester);
    final target = find.byType(InteractiveViewer).hitTestable();
    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(
      visibleTransform(tester).value.getMaxScaleOnAxis(),
      closeTo(2, 0.001),
    );
    expect(pageView(tester).physics, isA<NeverScrollableScrollPhysics>());

    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(
      visibleTransform(tester).value.getMaxScaleOnAxis(),
      closeTo(1, 0.001),
    );
    expect(pageView(tester).physics, isA<PageScrollPhysics>());
  });

  testWidgets('the close button pops the viewer', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(VenuePhotoViewerPage), findsNothing);
  });
}
