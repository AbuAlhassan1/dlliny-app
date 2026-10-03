import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/gallery_requests.dart';
import 'package:hangout/domain/dto/response/business_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/presentation/venue/controllers/manage_gallery/manage_gallery_bloc.dart';
import 'package:hangout/presentation/venue/pages/venue_gallery_manager_page.dart';
import 'package:hangout/presentation/venue/pages/venue_photo_viewer_page.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:hangout/presentation/venue/utils/gallery_upload.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gallery_test_helper.dart';
import '../../helpers/locale_test_helper.dart';
import '../../helpers/test_harness.dart';

class _MockImagePicker extends Mock implements ImagePicker {}

const _owner = [VenuePerm.update, VenuePerm.mediaUpload, VenuePerm.mediaDelete];
const _staff = ['venue:read', VenuePerm.mediaUpload];

const _grant = GalleryUploadUrlResponse(
  uploadUrl: 'https://s3.test/put',
  key: 'venues/venue-1/gallery/0f8fad5b-d9cb-469f-a165-70867728950e.jpg',
  expiresInSeconds: 300,
  maxBytes: 10485760,
);

Future<PreparedGalleryFile> _prepare(XFile file) async => PreparedGalleryFile(
  bytes: Uint8List(2048),
  contentType: 'image/jpeg',
  width: 1536,
  height: 2048,
  placeholderHash: kSampleThumbHash,
);

Future<void> _upload(String url, String type, Uint8List bytes) async {}

void main() {
  late MockApiService api;
  late _MockImagePicker picker;

  final photos = [
    buildGalleryPhoto('a', tags: ['inside']),
    buildGalleryPhoto(
      'b',
      hidden: true,
      hiddenReason: 'يظهر زبائن',
      tags: ['family_section'],
    ),
    buildGalleryPhoto('c', locationId: 'b-karrada'),
  ];
  final branches = [
    buildBranch('b-karrada', labelAr: 'الكرادة', isPrimary: true),
    buildBranch('b-mansour', labelAr: 'المنصور', sortOrder: 1),
  ];

  setUpAll(() async {
    await loadTestLocale('ar');
    registerFallbackValue(ImageSource.gallery);
    registerFallbackValue(
      const AttachGalleryPhotoRequest(key: 'k', width: 1, height: 1),
    );
    registerFallbackValue(const UpdateGalleryPhotoRequest());
    registerFallbackValue(const ReorderGalleryRequest(photoIds: []));
  });

  void answerList(List<GalleryPhotoDto> list) {
    when(() => api.businessListGallery(kGalleryVenueId)).thenAnswer(
      (_) async => apiOk(
        BusinessGalleryResponse(
          photos: list,
          maxPhotos: 24,
          remaining: 24 - list.length,
        ),
      ),
    );
  }

  setUp(() async {
    await resetLocator();
    api = MockApiService();
    putSingleton<ApiService>(api);
    picker = _MockImagePicker();
    answerList(photos);
  });

  tearDown(resetLocator);

  Future<void> pump(
    WidgetTester tester,
    List<String> perms, {
    GalleryFilePreparer? prepare,
  }) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      galleryHost(
        VenueGalleryManagerPage(
          venueId: kGalleryVenueId,
          branches: branches,
          picker: picker,
          prepare: prepare ?? _prepare,
          upload: _upload,
        ),
        perms: perms,
        scrollable: false,
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<bool? Function()> open(
    WidgetTester tester, {
    GalleryS3Uploader upload = _upload,
  }) async {
    bool? popped;
    usePhoneSurface(tester);
    await tester.pumpWidget(
      galleryHost(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => VenueGalleryManagerPage(
                        venueId: kGalleryVenueId,
                        branches: branches,
                        picker: picker,
                        prepare: _prepare,
                        upload: upload,
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        perms: _owner,
        scrollable: false,
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => popped;
  }

  void pickReturns(List<String> paths) {
    when(
      () => picker.pickMultiImage(
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => [for (final p in paths) XFile(p)]);
  }

  Future<void> addBatch(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('gallery-manager-add')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('gallery-batch-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Finder tile(String id) => find.byKey(ValueKey('gallery-manager-photo-$id'));
  final uploadTiles = find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith(
          'gallery-manager-upload-',
        ),
  );
  final progress = find.byKey(const ValueKey('gallery-manager-progress'));
  final reorder = find.byKey(const ValueKey('gallery-manager-reorder'));
  final add = find.byKey(const ValueKey('gallery-manager-add'));
  final staffHint = find.text(
    'يمكنك إضافة صور؛ الترتيب والحذف للمالك والمدير.',
  );

  group('owner / manager', () {
    testWidgets('counter, reorder, and no staff hint', (tester) async {
      await pump(tester, _owner);
      expect(find.text('3 / 24'), findsOneWidget);
      expect(reorder, findsOneWidget);
      expect(staffHint, findsNothing);
      expect(tile('a'), findsOneWidget);
      expect(find.text('مخفية من الإدارة'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('3 / 24')).textDirection,
        TextDirection.ltr,
      );
    });

    testWidgets('tiles are labelled buttons for screen readers', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, _owner);
      expect(
        tester.getSemantics(tile('a')),
        isSemantics(
          label: 'من الداخل · 1 من 3',
          isButton: true,
          hasTapAction: true,
        ),
      );
      expect(
        tester.getSemantics(tile('b')),
        isSemantics(
          label: 'مخفية من الإدارة · قسم العوائل · 2 من 3',
          isButton: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('a photo opens the edit sheet: tags, branch, delete', (
      tester,
    ) async {
      await pump(tester, _owner);
      await tester.tap(tile('b'));
      await tester.pumpAndSettle();
      expect(find.text('الوسوم'), findsOneWidget);
      expect(find.text('3 وسوم كحد أقصى'), findsOneWidget);
      expect(find.text('الفرع'), findsOneWidget);
      expect(find.byKey(const ValueKey('gallery-edit-delete')), findsOneWidget);
      expect(find.textContaining('السبب: يظهر زبائن'), findsOneWidget);
      expect(
        find.text(
          'لا تنشر صوراً يظهر فيها زبائن يمكن التعرف عليهم دون موافقتهم.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('editing tags sends one PATCH with the new list', (
      tester,
    ) async {
      when(
        () => api.businessUpdateGalleryPhoto(kGalleryVenueId, 'a', any()),
      ).thenAnswer(
        (_) async => apiOk(buildGalleryPhoto('a', tags: ['inside', 'view'])),
      );
      await pump(tester, _owner);
      await tester.tap(tile('a'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الإطلالة'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('gallery-edit-save')));
      await tester.pumpAndSettle();

      final body =
          verify(
                () => api.businessUpdateGalleryPhoto(
                  kGalleryVenueId,
                  'a',
                  captureAny(),
                ),
              ).captured.single
              as UpdateGalleryPhotoRequest;
      expect(body.toJson(), {
        'tags': ['inside', 'view'],
      });
    });

    testWidgets('a 4th tag is disabled', (tester) async {
      await pump(tester, _owner);
      await tester.tap(tile('a'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الإطلالة'));
      await tester.pump();
      await tester.tap(find.text('الأجواء'));
      await tester.pump();
      await tester.tap(find.text('الجلسات'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('gallery-edit-save')));
      await tester.pumpAndSettle();
      final body =
          verify(
                () => api.businessUpdateGalleryPhoto(
                  kGalleryVenueId,
                  'a',
                  captureAny(),
                ),
              ).captured.single
              as UpdateGalleryPhotoRequest;
      expect(body.tags, ['inside', 'view', 'ambience']);
    });

    testWidgets('delete asks first, then removes the photo', (tester) async {
      when(
        () => api.businessDeleteGalleryPhoto(kGalleryVenueId, 'a'),
      ).thenAnswer((_) async => apiOk<dynamic>(null));
      await pump(tester, _owner);
      await tester.tap(tile('a'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('gallery-edit-delete')));
      await tester.pumpAndSettle();
      expect(find.text('حذف الصورة؟'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gallery-delete-confirm')));
      await tester.pumpAndSettle();
      verify(
        () => api.businessDeleteGalleryPhoto(kGalleryVenueId, 'a'),
      ).called(1);
      expect(tile('a'), findsNothing);
      expect(find.text('2 / 24'), findsOneWidget);
    });

    testWidgets('reorder mode lists every photo and saves on «تم»', (
      tester,
    ) async {
      when(() => api.businessReorderGallery(kGalleryVenueId, any())).thenAnswer(
        (_) async => apiOk(
          BusinessGalleryResponse(
            photos: photos.reversed.toList(),
            maxPhotos: 24,
            remaining: 21,
          ),
        ),
      );
      await pump(tester, _owner);
      await tester.tap(reorder);
      await tester.pumpAndSettle();
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(add, findsNothing);
      expect(find.byIcon(TablerIcons.grip_vertical), findsNWidgets(3));

      await tester.tap(reorder);
      await tester.pumpAndSettle();
      verifyNever(() => api.businessReorderGallery(any(), any()));
      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets('reorder: dragging a grip moves the photo, and «تم» PUTs '
        'the new order', (tester) async {
      when(() => api.businessReorderGallery(kGalleryVenueId, any())).thenAnswer(
        (_) async => apiOk(
          BusinessGalleryResponse(
            photos: [photos[1], photos[0], photos[2]],
            maxPhotos: 24,
            remaining: 21,
          ),
        ),
      );
      await pump(tester, _owner);
      await tester.tap(reorder);
      await tester.pumpAndSettle();

      final grip = find.byIcon(TablerIcons.grip_vertical).first;
      final gesture = await tester.startGesture(tester.getCenter(grip));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await gesture.moveBy(const Offset(0, 10));
        await tester.pump();
      }
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(reorder);
      await tester.pumpAndSettle();
      final body =
          verify(
                () => api.businessReorderGallery(kGalleryVenueId, captureAny()),
              ).captured.single
              as ReorderGalleryRequest;
      expect(body.photoIds, ['b', 'a', 'c']);
      expect(tile('b'), findsOneWidget);
    });

    testWidgets('one free slot: the picker is pickImage, never '
        'pickMultiImage(limit: 1)', (tester) async {
      answerList([for (var i = 0; i < 23; i++) buildGalleryPhoto('p$i')]);
      when(
        () => picker.pickImage(
          source: any(named: 'source'),
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
        ),
      ).thenAnswer((_) async => null);
      await pump(tester, _owner);
      expect(find.text('23 / 24'), findsOneWidget);
      await tester.tap(add);
      await tester.pumpAndSettle();
      verify(
        () => picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 85,
        ),
      ).called(1);
      verifyNever(
        () => picker.pickMultiImage(
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
          limit: any(named: 'limit'),
        ),
      );
    });

    testWidgets('add flow: pick → batch tags → upload → attach, then the '
        'page pops with true', (tester) async {
      pickReturns(['/picked/a.jpg', '/picked/b.jpg']);
      when(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).thenAnswer((_) async => apiOk(_grant));
      var n = 0;
      when(
        () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
      ).thenAnswer(
        (_) async => apiOk(buildGalleryPhoto('new${n++}', tags: ['inside'])),
      );
      final puts = <int>[];
      final popped = await open(
        tester,
        upload: (url, type, bytes) async => puts.add(bytes.length),
      );

      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.text('من الداخل'));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('gallery-batch-confirm')));
      await tester.pumpAndSettle();

      expect(puts, [2048, 2048]);
      final bodies = verify(
        () => api.businessAttachGalleryPhoto(kGalleryVenueId, captureAny()),
      ).captured.cast<AttachGalleryPhotoRequest>();
      expect(bodies.map((b) => b.tags), [
        ['inside'],
        ['inside'],
      ]);
      expect(find.text('5 / 24'), findsOneWidget);
      expect(tile('new0'), findsOneWidget);
      expect(tile('new1'), findsOneWidget);
      expect(uploadTiles, findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(popped(), isTrue);
    });

    testWidgets('mid-batch, a finished photo shows once — not also as a '
        'spinning upload tile', (tester) async {
      pickReturns(['/picked/a.jpg', '/picked/b.jpg']);
      when(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).thenAnswer((_) async => apiOk(_grant));
      final second = Completer<ApiResponse<GalleryPhotoDto>>();
      var n = 0;
      when(
        () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
      ).thenAnswer((_) {
        if (n++ == 0) return Future.value(apiOk(buildGalleryPhoto('new0')));
        return second.future;
      });
      await pump(tester, _owner);
      await addBatch(tester);

      expect(tile('new0'), findsOneWidget);
      expect(uploadTiles, findsOneWidget, reason: 'only b.jpg is in flight');
      expect(find.text('4 / 24'), findsOneWidget);
      expect(tester.widget<Text>(progress).data, 'جارٍ الرفع 1 من 2');

      second.complete(apiOk(buildGalleryPhoto('new1')));
      await tester.pump();
      await tester.pump();
      expect(uploadTiles, findsNothing);
      expect(progress, findsNothing);
      expect(tile('new1'), findsOneWidget);
      expect(find.text('5 / 24'), findsOneWidget);
    });

    testWidgets('back mid-upload asks first: «متابعة الرفع» stays; leaving '
        'drops the waiting files and pops once the one in flight is done', (
      tester,
    ) async {
      pickReturns(['/picked/a.jpg', '/picked/b.jpg', '/picked/c.jpg']);
      when(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).thenAnswer((_) async => apiOk(_grant));
      final first = Completer<ApiResponse<GalleryPhotoDto>>();
      when(
        () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
      ).thenAnswer((_) => first.future);
      final popped = await open(tester);
      await addBatch(tester);
      expect(uploadTiles, findsNWidgets(3));

      Future<void> back() async {
        await tester.tap(find.byType(BackButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      await back();
      expect(find.text('لم يكتمل رفع الصور'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('gallery-leave-stay')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(VenueGalleryManagerPage), findsOneWidget);
      expect(uploadTiles, findsNWidgets(3));

      await back();
      await tester.tap(find.byKey(const ValueKey('gallery-leave-confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(VenueGalleryManagerPage), findsOneWidget);
      expect(uploadTiles, findsOneWidget);
      expect(tester.widget<Text>(progress).data, 'جارٍ إنهاء الصورة الحالية…');
      expect(add, findsNothing);
      expect(popped(), isNull);

      first.complete(apiOk(buildGalleryPhoto('new0')));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(VenueGalleryManagerPage), findsNothing);
      expect(popped(), isTrue, reason: 'the reload now includes a.jpg');
      verify(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).called(1);
    });

    testWidgets('a second back while the last file finishes pops at once '
        '(never trapped by a stalled network)', (tester) async {
      pickReturns(['/picked/a.jpg']);
      when(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).thenAnswer((_) async => apiOk(_grant));
      final stalled = Completer<ApiResponse<GalleryPhotoDto>>();
      when(
        () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
      ).thenAnswer((_) => stalled.future);
      final popped = await open(tester);
      await addBatch(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('gallery-leave-confirm')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(VenueGalleryManagerPage), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pump();
      stalled.complete(apiOk(buildGalleryPhoto('new0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(VenueGalleryManagerPage), findsNothing);
      expect(find.text('open'), findsOneWidget, reason: 'the host page stays');
      expect(popped(), isTrue);
    });

    testWidgets('the batch sheet can\'t be swiped or tapped away; «إلغاء» '
        'uploads nothing', (tester) async {
      pickReturns(['/picked/a.jpg']);
      await pump(tester, _owner);
      await tester.tap(add);
      await tester.pumpAndSettle();
      final title = find.text('وسوم لهذه الصور (اختياري)');
      expect(title, findsOneWidget);

      await tester.drag(title, const Offset(0, 500));
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
      await tester.tapAt(const Offset(20, 60));
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);

      final cancel = find.byKey(const ValueKey('gallery-batch-cancel'));
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(title, findsNothing);
      expect(uploadTiles, findsNothing);
      verifyNever(() => api.businessGetGalleryUploadUrl(any(), any(), any()));
    });

    testWidgets('GALLERY_RATE_LIMITED mid-queue: one toast, every waiting '
        'file failed', (tester) async {
      final toasts = <AppToastMessage>[];
      final sub = appToast.stream.listen(toasts.add);
      addTearDown(sub.cancel);
      pickReturns(['/picked/a.jpg', '/picked/b.jpg', '/picked/c.jpg']);
      when(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).thenThrow(
        dioErrorWithMessage(
          'GALLERY_RATE_LIMITED: too many uploads, try again later',
        ),
      );
      await pump(tester, _owner);
      await addBatch(tester);

      expect(uploadTiles, findsNWidgets(3));
      expect(find.text('فشل رفع الصورة'), findsNWidgets(3));
      expect(toasts.map((t) => t.text), ['رفعت صوراً كثيرة، حاول بعد قليل']);
      verify(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).called(1);
    });

    testWidgets('BRANCH_NOT_FOUND on attach says the branch is gone and that '
        'a retry goes venue-wide', (tester) async {
      final toasts = <AppToastMessage>[];
      final sub = appToast.stream.listen(toasts.add);
      addTearDown(sub.cancel);
      pickReturns(['/picked/a.jpg']);
      when(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).thenAnswer((_) async => apiOk(_grant));
      when(
        () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
      ).thenThrow(
        dioErrorWithMessage(
          'BRANCH_NOT_FOUND: branch not found',
          statusCode: 404,
        ),
      );
      await pump(tester, _owner);
      await addBatch(tester);
      expect(toasts.single.text, 'الفرع المختار لم يعد متاحاً');
      expect(toasts.single.body, 'أعد المحاولة لتُضاف الصورة لكل الفروع');
    });

    testWidgets('a failed file: a 48 dp retry that re-runs it, and it is '
        'not counted in the next batch\'s «n من m»', (tester) async {
      var n = 0;
      pickReturns(['/picked/a.jpg']);
      when(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).thenAnswer((_) async => apiOk(_grant));
      when(
        () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
      ).thenAnswer((_) => Completer<ApiResponse<GalleryPhotoDto>>().future);
      await pump(
        tester,
        _owner,
        prepare: (file) async {
          if (n++ == 0) throw const GalleryUploadException('GALLERY_TOO_LARGE');
          return _prepare(file);
        },
      );
      await addBatch(tester);
      final retry = find.byKey(const ValueKey('gallery-manager-retry-0'));
      expect(retry, findsOneWidget);
      expect(tester.getSize(retry).height, greaterThanOrEqualTo(48));
      expect(progress, findsNothing);

      await addBatch(tester);
      expect(tester.widget<Text>(progress).data, 'جارٍ الرفع 0 من 1');

      await tester.tap(retry);
      await tester.pump();
      expect(tester.widget<Text>(progress).data, 'جارٍ الرفع 0 من 2');
      expect(retry, findsNothing);
      expect(uploadTiles, findsNWidgets(2));
      expect(n, 2);
    });

    testWidgets('24 photos: «إضافة صور» is disabled and says why', (
      tester,
    ) async {
      answerList([for (var i = 0; i < 24; i++) buildGalleryPhoto('p$i')]);
      await pump(tester, _owner);
      expect(find.text('وصلت للحد الأقصى (24 صورة)'), findsOneWidget);
      expect(tester.widget<ButtonStyleButton>(add).onPressed, isNull);
    });
  });

  group('staff (upload only)', () {
    testWidgets('sees the hint and can add, but no manager controls', (
      tester,
    ) async {
      await pump(tester, _staff);
      expect(staffHint, findsOneWidget);
      expect(reorder, findsNothing);
      expect(tester.widget<ButtonStyleButton>(add).onPressed, isNotNull);
    });

    testWidgets('a photo opens the viewer, never the edit sheet', (
      tester,
    ) async {
      await pump(tester, _staff);
      await tester.tap(tile('a'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('gallery-edit-delete')), findsNothing);
      expect(find.byType(VenuePhotoViewerPage), findsOneWidget);
    });

    testWidgets('a hidden photo tells staff why, and opens nothing', (
      tester,
    ) async {
      final toasts = <AppToastMessage>[];
      final sub = appToast.stream.listen(toasts.add);
      addTearDown(sub.cancel);
      await pump(tester, _staff);
      await tester.tap(tile('b'));
      await tester.pumpAndSettle();
      expect(find.byType(VenuePhotoViewerPage), findsNothing);
      expect(find.byKey(const ValueKey('gallery-edit-delete')), findsNothing);
      expect(toasts.single.text, 'مخفية من الإدارة');
      expect(toasts.single.body, 'السبب: يظهر زبائن');
    });

    testWidgets('the batch sheet offers tags and the branch to staff too', (
      tester,
    ) async {
      when(
        () => picker.pickMultiImage(
          maxWidth: any(named: 'maxWidth'),
          maxHeight: any(named: 'maxHeight'),
          imageQuality: any(named: 'imageQuality'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [XFile('/picked/a.jpg')]);
      await pump(tester, _staff);
      await tester.tap(add);
      await tester.pumpAndSettle();
      verify(
        () => picker.pickMultiImage(
          maxWidth: 2560,
          maxHeight: 2560,
          imageQuality: 85,
          limit: 21,
        ),
      ).called(1);
      expect(find.text('وسوم لهذه الصور (اختياري)'), findsOneWidget);
      expect(find.text('الفرع'), findsOneWidget);
      await tester.tap(find.text('الغرف الخاصة'));
      await tester.pump();
      expect(
        find.text(
          'لا تنشر صوراً يظهر فيها زبائن يمكن التعرف عليهم دون موافقتهم.',
        ),
        findsOneWidget,
      );
    });
  });
}
