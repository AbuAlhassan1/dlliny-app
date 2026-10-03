import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/gallery_requests.dart';
import 'package:hangout/domain/dto/response/business_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/presentation/venue/controllers/manage_gallery/manage_gallery_bloc.dart';
import 'package:hangout/presentation/venue/utils/gallery_upload.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gallery_test_helper.dart';
import '../../helpers/test_harness.dart';

Future<void> _settle() async {
  for (var i = 0; i < 30; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

const _key = 'venues/venue-1/gallery/0f8fad5b-d9cb-469f-a165-70867728950e.jpg';
final Uint8List _bytes = Uint8List.fromList(List.filled(1234, 7));

GalleryUploadUrlResponse _grant({String key = _key}) =>
    GalleryUploadUrlResponse(
      uploadUrl: 'https://s3.test/put?sig=1',
      key: key,
      expiresInSeconds: 300,
      maxBytes: 10485760,
    );

BusinessGalleryResponse _list(List<GalleryPhotoDto> photos) =>
    BusinessGalleryResponse(
      photos: photos,
      maxPhotos: 24,
      remaining: 24 - photos.length,
    );

void main() {
  late MockApiService api;
  late List<String> puts;
  late int prepared;

  setUpAll(() {
    registerFallbackValue(
      const AttachGalleryPhotoRequest(key: 'k', width: 1, height: 1),
    );
    registerFallbackValue(const UpdateGalleryPhotoRequest());
    registerFallbackValue(const ReorderGalleryRequest(photoIds: []));
  });

  setUp(() async {
    await resetLocator();
    api = MockApiService();
    putSingleton<ApiService>(api);
    puts = [];
    prepared = 0;
    when(
      () => api.businessListGallery(kGalleryVenueId),
    ).thenAnswer((_) async => apiOk(_list([buildGalleryPhoto('p1')])));
    when(
      () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
    ).thenAnswer((_) async => apiOk(_grant()));
    when(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
    ).thenAnswer(
      (_) async => apiOk(buildGalleryPhoto('new', tags: ['inside'])),
    );
  });

  tearDown(resetLocator);

  Future<PreparedGalleryFile> fakePrepare(XFile file) async {
    prepared++;
    return PreparedGalleryFile(
      bytes: _bytes,
      contentType: 'image/jpeg',
      width: 1536,
      height: 2048,
      placeholderHash: file.path.endsWith('no-hash.jpg')
          ? null
          : kSampleThumbHash,
    );
  }

  Future<void> fakeUpload(String url, String type, Uint8List bytes) async {
    puts.add('$url|$type|${bytes.length}');
  }

  ManageGalleryBloc build({
    bool canManage = true,
    GalleryFilePreparer? prepare,
    GalleryS3Uploader? upload,
  }) => ManageGalleryBloc(
    venueId: kGalleryVenueId,
    canManage: canManage,
    prepare: prepare ?? fakePrepare,
    upload: upload ?? fakeUpload,
  );

  Future<List<ManageGalleryState>> run(
    ManageGalleryBloc bloc,
    List<ManageGalleryEvent> events,
  ) async {
    bloc.add(const GalleryLoadRequested());
    await _settle();
    final states = <ManageGalleryState>[];
    final sub = bloc.stream.listen(states.add);
    for (final e in events) {
      bloc.add(e);
      await _settle();
    }
    await sub.cancel();
    return states;
  }

  XFile file([String name = 'a.jpg']) =>
      XFile.fromData(_bytes, path: '/picked/$name');

  test('load: every photo (hidden ones count) and the free slots', () async {
    when(() => api.businessListGallery(kGalleryVenueId)).thenAnswer(
      (_) async => apiOk(
        _list([buildGalleryPhoto('p1'), buildGalleryPhoto('p2', hidden: true)]),
      ),
    );
    final bloc = build();
    await run(bloc, const []);
    expect(bloc.state.status, ManageGalleryStatus.ready);
    expect(bloc.state.photos, hasLength(2));
    expect(bloc.state.remaining, 22);
    expect(bloc.state.changed, isFalse);
    await bloc.close();
  });

  test('an upload walks preparing → uploading → attaching → done', () async {
    final bloc = build();
    final states = await run(bloc, [
      GalleryPhotosPicked(
        [file()],
        tags: ['inside', 'bogus'],
        locationId: 'b1',
      ),
    ]);

    final statuses = <GalleryUploadStatus>{
      for (final s in states)
        if (s.uploads.isNotEmpty) s.uploads.single.status,
    }.toList();
    expect(statuses, [
      GalleryUploadStatus.queued,
      GalleryUploadStatus.preparing,
      GalleryUploadStatus.uploading,
      GalleryUploadStatus.attaching,
      GalleryUploadStatus.done,
    ]);

    verify(
      () =>
          api.businessGetGalleryUploadUrl(kGalleryVenueId, 'image/jpeg', 1234),
    ).called(1);
    expect(puts, ['https://s3.test/put?sig=1|image/jpeg|1234']);

    final attach =
        verify(
              () =>
                  api.businessAttachGalleryPhoto(kGalleryVenueId, captureAny()),
            ).captured.single
            as AttachGalleryPhotoRequest;
    expect(attach.toJson(), {
      'key': _key,
      'width': 1536,
      'height': 2048,
      'placeholderHash': kSampleThumbHash,
      'tags': ['inside'],
      'venueLocationId': 'b1',
    });

    expect(bloc.state.uploads, isEmpty);
    expect(bloc.state.photos.map((p) => p.id), ['p1', 'new']);
    expect(bloc.state.changed, isTrue);
    await bloc.close();
  });

  test('a failed ThumbHash (null) still uploads, without the field', () async {
    final bloc = build();
    await run(bloc, [
      GalleryPhotosPicked([file('no-hash.jpg')]),
    ]);
    final attach =
        verify(
              () =>
                  api.businessAttachGalleryPhoto(kGalleryVenueId, captureAny()),
            ).captured.single
            as AttachGalleryPhotoRequest;
    expect(attach.toJson().containsKey('placeholderHash'), isFalse);
    expect(bloc.state.photos.map((p) => p.id), contains('new'));
    await bloc.close();
  });

  test(
    '409 GALLERY_DUPLICATE_KEY on attach counts as done and reloads',
    () async {
      when(
        () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
      ).thenThrow(
        dioErrorWithMessage(
          'GALLERY_DUPLICATE_KEY: this upload is already attached',
          statusCode: 409,
        ),
      );
      final bloc = build();
      final states = await run(bloc, [
        GalleryPhotosPicked([file()]),
      ]);

      expect(
        states.expand((s) => s.uploads).map((u) => u.status),
        isNot(contains(GalleryUploadStatus.failed)),
      );
      expect(
        states.map((s) => s.notice).whereType<ManageGalleryNotice>(),
        isEmpty,
      );
      expect(bloc.state.uploads, isEmpty);
      expect(bloc.state.changed, isTrue);
      verify(() => api.businessListGallery(kGalleryVenueId)).called(2);
      await bloc.close();
    },
  );

  test('a retry after a failed attach re-attaches the same key only', () async {
    var attachCalls = 0;
    when(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
    ).thenAnswer((_) async {
      if (attachCalls++ == 0) throw dioTimeout();
      return apiOk(buildGalleryPhoto('new'));
    });
    final bloc = build();
    await run(bloc, [
      GalleryPhotosPicked([file()]),
    ]);
    final failed = bloc.state.uploads.single;
    expect(failed.status, GalleryUploadStatus.failed);
    expect(failed.key, _key);
    expect(bloc.state.remaining, 22, reason: 'a failed upload keeps its slot');

    bloc.add(GalleryUploadRetried(failed.localId));
    await _settle();
    expect(bloc.state.uploads, isEmpty);
    expect(bloc.state.photos.map((p) => p.id), ['p1', 'new']);
    expect(prepared, 1);
    expect(puts, hasLength(1));
    verify(
      () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
    ).called(1);
    final keys = verify(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, captureAny()),
    ).captured.map((r) => (r as AttachGalleryPhotoRequest).key);
    expect(keys, [_key, _key]);
    await bloc.close();
  });

  test('a failed S3 PUT retries from a fresh upload URL', () async {
    var putCalls = 0;
    final bloc = build(
      upload: (url, type, bytes) async {
        if (putCalls++ == 0) throw dioTimeout();
      },
    );
    await run(bloc, [
      GalleryPhotosPicked([file()]),
    ]);
    final failed = bloc.state.uploads.single;
    expect(failed.status, GalleryUploadStatus.failed);
    expect(failed.key, isNull);

    bloc.add(GalleryUploadRetried(failed.localId));
    await _settle();
    expect(bloc.state.uploads, isEmpty);
    verify(
      () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
    ).called(2);
    await bloc.close();
  });

  test(
    'GALLERY_LIMIT_REACHED fails the waiting files too and reloads',
    () async {
      when(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).thenThrow(
        dioErrorWithMessage(
          'GALLERY_LIMIT_REACHED: at most 24 photos per venue',
          statusCode: 409,
        ),
      );
      final bloc = build();
      final states = await run(bloc, [
        GalleryPhotosPicked([file('a.jpg'), file('b.jpg'), file('c.jpg')]),
      ]);
      expect(
        bloc.state.uploads.map((u) => (u.status, u.errorCode)),
        List.filled(3, (
          GalleryUploadStatus.failed,
          VenueErrorCodes.galleryLimitReached,
        )),
      );
      verify(
        () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
      ).called(1);
      verify(() => api.businessListGallery(kGalleryVenueId)).called(2);
      expect(states.last.notice?.code, VenueErrorCodes.galleryLimitReached);
      await bloc.close();
    },
  );

  test(
    '5 picked with 3 free slots: uploads 3 and says the limit is reached',
    () async {
      when(() => api.businessListGallery(kGalleryVenueId)).thenAnswer(
        (_) async => apiOk(
          _list([for (var i = 0; i < 21; i++) buildGalleryPhoto('p$i')]),
        ),
      );
      var n = 0;
      when(
        () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
      ).thenAnswer((_) async => apiOk(buildGalleryPhoto('new${n++}')));
      final bloc = build();
      final states = await run(bloc, [
        GalleryPhotosPicked([for (var i = 0; i < 5; i++) file('f$i.jpg')]),
      ]);
      expect(states.first.uploads, hasLength(3));
      expect(states.first.notice?.code, VenueErrorCodes.galleryLimitReached);
      expect(puts, hasLength(3));
      expect(bloc.state.photos, hasLength(24));
      expect(bloc.state.remaining, 0);
      await bloc.close();
    },
  );

  test('a finished item leaves the grid at once, before the batch drains '
      '(no photo shown twice)', () async {
    final second = Completer<ApiResponse<GalleryPhotoDto>>();
    var n = 0;
    when(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
    ).thenAnswer((_) {
      if (n++ == 0) return Future.value(apiOk(buildGalleryPhoto('new0')));
      return second.future;
    });
    final bloc = build();
    await run(bloc, [
      GalleryPhotosPicked([file('a.jpg'), file('b.jpg')]),
    ]);

    final state = bloc.state;
    expect(state.photos.map((p) => p.id), ['p1', 'new0']);
    expect(state.pendingUploads.map((u) => u.status), [
      GalleryUploadStatus.attaching,
    ]);
    expect(state.uploadsDone, 1);
    expect(state.uploadsTotal, 2);
    expect(state.uploading, isTrue);

    second.complete(apiOk(buildGalleryPhoto('new1')));
    await _settle();
    expect(bloc.state.uploads, isEmpty);
    expect(bloc.state.photos.map((p) => p.id), ['p1', 'new0', 'new1']);
    await bloc.close();
  });

  test('a failed item is not counted in the next batch\'s total', () async {
    var n = 0;
    final hang = Completer<ApiResponse<GalleryPhotoDto>>();
    when(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
    ).thenAnswer((_) => hang.future);
    final bloc = build(
      prepare: (f) async {
        if (n++ == 0) {
          throw const GalleryUploadException(
            VenueErrorCodes.galleryUnsupportedType,
          );
        }
        return fakePrepare(f);
      },
    );
    await run(bloc, [
      GalleryPhotosPicked([file('bad.gif')]),
      GalleryPhotosPicked([file('good.jpg')]),
    ]);
    expect(bloc.state.pendingUploads.map((u) => u.status), [
      GalleryUploadStatus.failed,
      GalleryUploadStatus.attaching,
    ]);
    expect(bloc.state.uploadsDone, 0);
    expect(bloc.state.uploadsTotal, 1);
    await bloc.close();
  });

  test('leaving: GalleryUploadsCancelled drops the waiting files, and the '
      'one in flight still finishes', () async {
    final first = Completer<ApiResponse<GalleryPhotoDto>>();
    when(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
    ).thenAnswer((_) => first.future);
    final bloc = build();
    await run(bloc, [
      GalleryPhotosPicked([file('a.jpg'), file('b.jpg'), file('c.jpg')]),
      const GalleryUploadsCancelled(),
    ]);
    expect(bloc.state.pendingUploads.map((u) => u.status), [
      GalleryUploadStatus.attaching,
    ]);
    expect(bloc.state.uploading, isTrue);

    first.complete(apiOk(buildGalleryPhoto('new')));
    await _settle();
    expect(bloc.state.uploading, isFalse);
    expect(bloc.state.uploads, isEmpty);
    expect(bloc.state.photos.map((p) => p.id), ['p1', 'new']);
    expect(bloc.state.changed, isTrue);
    expect(prepared, 1);
    verify(
      () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
    ).called(1);
    await bloc.close();
  });

  test('GALLERY_RATE_LIMITED fails the whole queue with ONE notice, and '
      'asks for no more upload URLs', () async {
    when(
      () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
    ).thenThrow(
      dioErrorWithMessage(
        'GALLERY_RATE_LIMITED: too many uploads, try again later',
      ),
    );
    final bloc = build();
    final states = await run(bloc, [
      GalleryPhotosPicked([for (var i = 0; i < 5; i++) file('f$i.jpg')]),
    ]);
    expect(
      bloc.state.uploads.map((u) => (u.status, u.errorCode)),
      List.filled(5, (
        GalleryUploadStatus.failed,
        VenueErrorCodes.galleryRateLimited,
      )),
    );
    verify(
      () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
    ).called(1);
    final notices = {
      for (final s in states)
        if (s.notice case final n?) n.serial,
    };
    expect(notices, hasLength(1), reason: 'one toast, not one per file');
    expect(states.last.notice?.code, VenueErrorCodes.galleryRateLimited);
    verify(() => api.businessListGallery(kGalleryVenueId)).called(1);
    await bloc.close();
  });

  test('GALLERY_OBJECT_MISSING on attach: the retry starts over from a '
      'fresh upload URL, and attaches the NEW key', () async {
    const freshKey =
        'venues/venue-1/gallery/7c9e6679-7425-40de-944b-e07fc1f90ae7.jpg';
    var grants = 0;
    when(
      () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
    ).thenAnswer(
      (_) async => apiOk(_grant(key: grants++ == 0 ? _key : freshKey)),
    );
    var attaches = 0;
    when(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
    ).thenAnswer((_) async {
      if (attaches++ == 0) {
        throw dioErrorWithMessage(
          'GALLERY_OBJECT_MISSING: upload the file first',
        );
      }
      return apiOk(buildGalleryPhoto('new'));
    });
    final bloc = build();
    await run(bloc, [
      GalleryPhotosPicked([file()]),
    ]);
    final failed = bloc.state.uploads.single;
    expect(failed.status, GalleryUploadStatus.failed);
    expect(failed.key, isNull, reason: 'that object is gone: re-upload');

    bloc.add(GalleryUploadRetried(failed.localId));
    await _settle();
    expect(bloc.state.uploads, isEmpty);
    expect(prepared, 2);
    expect(puts, hasLength(2));
    verify(
      () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
    ).called(2);
    final keys = verify(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, captureAny()),
    ).captured.map((r) => (r as AttachGalleryPhotoRequest).key);
    expect(keys, [_key, freshKey]);
    await bloc.close();
  });

  test('BRANCH_NOT_FOUND on attach: the branch is cleared, so the retry '
      'attaches the same key venue-wide', () async {
    var attaches = 0;
    when(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, any()),
    ).thenAnswer((_) async {
      if (attaches++ == 0) {
        throw dioErrorWithMessage(
          'BRANCH_NOT_FOUND: branch not found',
          statusCode: 404,
        );
      }
      return apiOk(buildGalleryPhoto('new'));
    });
    final bloc = build();
    final states = await run(bloc, [
      GalleryPhotosPicked([file()], locationId: 'b-gone'),
    ]);
    final failed = bloc.state.uploads.single;
    expect(failed.status, GalleryUploadStatus.failed);
    expect(failed.errorCode, VenueErrorCodes.branchNotFound);
    expect(failed.locationId, isNull);
    expect(failed.key, _key, reason: 'the upload itself is fine');
    expect(states.last.notice?.branchCleared, isTrue);

    bloc.add(GalleryUploadRetried(failed.localId));
    await _settle();
    expect(bloc.state.uploads, isEmpty);
    verify(
      () => api.businessGetGalleryUploadUrl(kGalleryVenueId, any(), any()),
    ).called(1);
    final bodies = verify(
      () => api.businessAttachGalleryPhoto(kGalleryVenueId, captureAny()),
    ).captured.cast<AttachGalleryPhotoRequest>();
    expect(bodies.map((b) => b.venueLocationId), ['b-gone', null]);
    await bloc.close();
  });

  test('a file the app rejects never asks for an upload URL', () async {
    final bloc = build(
      prepare: (_) async => throw const GalleryUploadException(
        VenueErrorCodes.galleryUnsupportedType,
      ),
    );
    final states = await run(bloc, [
      GalleryPhotosPicked([file()]),
    ]);
    expect(bloc.state.uploads.single.status, GalleryUploadStatus.failed);
    expect(
      bloc.state.uploads.single.errorCode,
      VenueErrorCodes.galleryUnsupportedType,
    );
    expect(states.last.notice?.code, VenueErrorCodes.galleryUnsupportedType);
    verifyNever(() => api.businessGetGalleryUploadUrl(any(), any(), any()));

    bloc.add(GalleryUploadDismissed(bloc.state.uploads.single.localId));
    await _settle();
    expect(bloc.state.uploads, isEmpty);
    expect(bloc.state.remaining, 23);
    await bloc.close();
  });

  group('owner / manager actions', () {
    setUp(() {
      when(() => api.businessListGallery(kGalleryVenueId)).thenAnswer(
        (_) async => apiOk(
          _list([
            buildGalleryPhoto('a'),
            buildGalleryPhoto('b', hidden: true),
            buildGalleryPhoto('c'),
          ]),
        ),
      );
    });

    test('staff cannot reorder, edit or delete (no request leaves)', () async {
      final bloc = build(canManage: false);
      await run(bloc, const [
        GalleryReorderCommitted(['c', 'b', 'a']),
        GalleryPhotoEdited('a', tags: ['view']),
        GalleryPhotoDeleted('a'),
      ]);
      verifyNever(() => api.businessReorderGallery(any(), any()));
      verifyNever(() => api.businessUpdateGalleryPhoto(any(), any(), any()));
      verifyNever(() => api.businessDeleteGalleryPhoto(any(), any()));
      expect(bloc.state.photos.map((p) => p.id), ['a', 'b', 'c']);
      await bloc.close();
    });

    test(
      'reorder sends every id (hidden included) and takes the server order',
      () async {
        when(
          () => api.businessReorderGallery(kGalleryVenueId, any()),
        ).thenAnswer(
          (_) async => apiOk(
            _list([
              buildGalleryPhoto('c'),
              buildGalleryPhoto('a'),
              buildGalleryPhoto('b', hidden: true),
            ]),
          ),
        );
        final bloc = build();
        await run(bloc, const [
          GalleryReorderCommitted(['c', 'a', 'b']),
        ]);
        final body =
            verify(
                  () =>
                      api.businessReorderGallery(kGalleryVenueId, captureAny()),
                ).captured.single
                as ReorderGalleryRequest;
        expect(body.photoIds, ['c', 'a', 'b']);
        expect(bloc.state.photos.map((p) => p.id), ['c', 'a', 'b']);
        expect(bloc.state.changed, isTrue);
        expect(bloc.state.busy, isFalse);
        await bloc.close();
      },
    );

    test('409 GALLERY_ORDER_MISMATCH reloads the list', () async {
      when(() => api.businessReorderGallery(kGalleryVenueId, any())).thenThrow(
        dioErrorWithMessage(
          'GALLERY_ORDER_MISMATCH: the gallery changed, refresh and retry',
          statusCode: 409,
        ),
      );
      final bloc = build();
      final states = await run(bloc, const [
        GalleryReorderCommitted(['c', 'a', 'b']),
      ]);
      verify(() => api.businessListGallery(kGalleryVenueId)).called(2);
      expect(states.last.notice?.code, VenueErrorCodes.galleryOrderMismatch);
      expect(bloc.state.photos.map((p) => p.id), ['a', 'b', 'c']);
      await bloc.close();
    });

    test('a failed reorder puts the old order back', () async {
      when(
        () => api.businessReorderGallery(kGalleryVenueId, any()),
      ).thenThrow(dioTimeout());
      final bloc = build();
      await run(bloc, const [
        GalleryReorderCommitted(['c', 'a', 'b']),
      ]);
      expect(bloc.state.photos.map((p) => p.id), ['a', 'b', 'c']);
      expect(bloc.state.changed, isFalse);
      await bloc.close();
    });

    test('edit PATCHes tags + branch in one request', () async {
      when(
        () => api.businessUpdateGalleryPhoto(kGalleryVenueId, 'a', any()),
      ).thenAnswer(
        (_) async =>
            apiOk(buildGalleryPhoto('a', tags: ['view'], locationId: 'b1')),
      );
      final bloc = build();
      await run(bloc, const [
        GalleryPhotoEdited('a', tags: ['view'], venueLocationId: 'b1'),
      ]);
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
        'tags': ['view'],
        'venueLocationId': 'b1',
      });
      expect(bloc.state.photos.first.tags, ['view']);
      await bloc.close();
    });

    test('delete removes the photo', () async {
      when(
        () => api.businessDeleteGalleryPhoto(kGalleryVenueId, 'b'),
      ).thenAnswer((_) async => apiOk<dynamic>(null));
      final bloc = build();
      await run(bloc, const [GalleryPhotoDeleted('b')]);
      expect(bloc.state.photos.map((p) => p.id), ['a', 'c']);
      expect(bloc.state.remaining, 22);
      expect(bloc.state.changed, isTrue);
      await bloc.close();
    });
  });
}
