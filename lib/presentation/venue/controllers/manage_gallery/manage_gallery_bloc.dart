import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/gallery_requests.dart';
import 'package:hangout/domain/dto/response/business_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';
import 'package:hangout/presentation/venue/utils/gallery_upload.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';
import 'package:image_picker/image_picker.dart';

part 'manage_gallery_event.dart';
part 'manage_gallery_state.dart';

typedef GalleryFilePreparer = Future<PreparedGalleryFile> Function(XFile file);

typedef GalleryS3Uploader =
    Future<void> Function(
      String uploadUrl,
      String contentType,
      Uint8List bytes,
    );

Future<void> putGalleryBytes(
  String uploadUrl,
  String contentType,
  Uint8List bytes,
) async {
  await Dio().put<void>(
    uploadUrl,
    data: Stream<List<int>>.value(bytes),
    options: Options(
      headers: {
        Headers.contentTypeHeader: contentType,
        Headers.contentLengthHeader: bytes.length,
      },
    ),
  );
}

class ManageGalleryBloc extends Bloc<ManageGalleryEvent, ManageGalleryState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;
  final bool canManage;
  final GalleryFilePreparer _prepare;
  final GalleryS3Uploader _upload;

  final List<GalleryPhotoDto> _photos = [];
  final List<GalleryUploadItem> _uploads = [];
  int _maxPhotos = kGalleryMaxPhotos;
  bool _loaded = false;
  bool _busy = false;
  bool _changed = false;
  bool _draining = false;
  int _nextLocalId = 0;
  int _noticeSerial = 0;
  ManageGalleryNotice? _notice;

  ManageGalleryBloc({
    required this.venueId,
    required this.canManage,
    GalleryFilePreparer prepare = prepareGalleryFile,
    GalleryS3Uploader upload = putGalleryBytes,
  }) : _prepare = prepare,
       _upload = upload,
       super(const ManageGalleryState()) {
    on<GalleryLoadRequested>(_onLoad);
    on<GalleryPhotosPicked>(_onPicked);
    on<GalleryUploadRetried>(_onRetried);
    on<GalleryUploadDismissed>(_onDismissed);
    on<GalleryUploadsCancelled>(_onCancelled);
    on<GalleryPhotoEdited>(_onEdited);
    on<GalleryReorderCommitted>(_onReorder);
    on<GalleryPhotoDeleted>(_onDeleted);
  }

  Future<void> _onLoad(
    GalleryLoadRequested event,
    Emitter<ManageGalleryState> emit,
  ) async {
    if (!_loaded) emit(_snapshot(status: ManageGalleryStatus.loading));
    final ok = await _fetch();
    if (!ok && _loaded) _noticeFor(null);
    emit(
      _snapshot(
        status: _loaded ? ManageGalleryStatus.ready : ManageGalleryStatus.error,
      ),
    );
  }

  Future<bool> _fetch() async {
    try {
      final res = await _api.businessListGallery(venueId);
      final data = res.data;
      if (!res.success || data == null) return false;
      _applyList(data);
      _loaded = true;
      return true;
    } catch (error, stackTrace) {
      log(
        'businessListGallery($venueId) failed: $error',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  void _applyList(BusinessGalleryResponse data) {
    _photos
      ..clear()
      ..addAll(data.photos);
    if (data.maxPhotos > 0) _maxPhotos = data.maxPhotos;
  }

  int get _remaining => math.max(
    0,
    _maxPhotos -
        _photos.length -
        _uploads.where((u) => u.status != GalleryUploadStatus.done).length,
  );

  Future<void> _onPicked(
    GalleryPhotosPicked event,
    Emitter<ManageGalleryState> emit,
  ) async {
    final slots = _remaining;
    final accepted = event.files.take(slots).toList();
    if (event.files.length > accepted.length) {
      _noticeFor(VenueErrorCodes.galleryLimitReached);
    }
    final tags = knownTags(event.tags).take(kGalleryMaxTagsPerPhoto).toList();
    for (final file in accepted) {
      _uploads.add(
        GalleryUploadItem(
          localId: _nextLocalId++,
          file: file,
          tags: tags,
          locationId: event.locationId,
        ),
      );
    }
    emit(_snapshot());
    await _drain(emit);
  }

  Future<void> _onRetried(
    GalleryUploadRetried event,
    Emitter<ManageGalleryState> emit,
  ) async {
    final i = _uploads.indexWhere((u) => u.localId == event.localId);
    if (i < 0 || _uploads[i].status != GalleryUploadStatus.failed) return;
    _uploads[i] = _uploads[i].copyWith(
      status: GalleryUploadStatus.queued,
      errorCode: () => null,
    );
    emit(_snapshot());
    await _drain(emit);
  }

  void _onDismissed(
    GalleryUploadDismissed event,
    Emitter<ManageGalleryState> emit,
  ) {
    _uploads.removeWhere(
      (u) =>
          u.localId == event.localId && u.status == GalleryUploadStatus.failed,
    );
    _pruneFinishedBatch();
    emit(_snapshot());
  }

  void _onCancelled(
    GalleryUploadsCancelled event,
    Emitter<ManageGalleryState> emit,
  ) {
    _uploads.removeWhere((u) => u.status == GalleryUploadStatus.queued);
    _pruneFinishedBatch();
    emit(_snapshot());
  }

  Future<void> _drain(Emitter<ManageGalleryState> emit) async {
    if (_draining) return;
    _draining = true;
    try {
      while (true) {
        final next = _uploads.indexWhere(
          (u) => u.status == GalleryUploadStatus.queued,
        );
        if (next < 0) break;
        await _process(_uploads[next].localId, emit);
      }
    } finally {
      _draining = false;
    }
    _pruneFinishedBatch();
    emit(_snapshot());
  }

  void _pruneFinishedBatch() {
    if (_uploads.any((u) => u.isActive)) return;
    _uploads.removeWhere((u) => u.status == GalleryUploadStatus.done);
  }

  Future<void> _process(int localId, Emitter<ManageGalleryState> emit) async {
    var item = _item(localId);

    if (item.key == null) {
      _update(
        localId,
        (u) => u.copyWith(status: GalleryUploadStatus.preparing),
      );
      emit(_snapshot());

      final PreparedGalleryFile prepared;
      try {
        prepared = await _prepare(item.file);
      } on GalleryUploadException catch (e) {
        _failItem(localId, e.code, emit);
        return;
      } catch (error, stackTrace) {
        log('gallery prepare failed: $error', stackTrace: stackTrace);
        _failItem(localId, null, emit);
        return;
      }

      _update(
        localId,
        (u) => u.copyWith(
          status: GalleryUploadStatus.uploading,
          width: prepared.width,
          height: prepared.height,
          placeholderHash: () => prepared.placeholderHash,
        ),
      );
      emit(_snapshot());

      final GalleryUploadUrlResponse grant;
      try {
        final res = await _api.businessGetGalleryUploadUrl(
          venueId,
          prepared.contentType,
          prepared.bytes.length,
        );
        final data = res.data;
        if (!res.success || data == null) {
          await _uploadRejected(localId, _codeOf(res), emit);
          return;
        }
        grant = data;
      } catch (error) {
        await _uploadRejected(localId, VenueApiError.from(error).code, emit);
        return;
      }
      if (prepared.bytes.length > grant.maxBytes) {
        _failItem(localId, VenueErrorCodes.galleryTooLarge, emit);
        return;
      }

      try {
        await _upload(grant.uploadUrl, prepared.contentType, prepared.bytes);
      } catch (error, stackTrace) {
        log('gallery S3 PUT failed: $error', stackTrace: stackTrace);
        _failItem(localId, null, emit);
        return;
      }
      _update(localId, (u) => u.copyWith(key: () => grant.key));
    }

    _update(localId, (u) => u.copyWith(status: GalleryUploadStatus.attaching));
    emit(_snapshot());
    item = _item(localId);
    try {
      final res = await _api.businessAttachGalleryPhoto(
        venueId,
        AttachGalleryPhotoRequest(
          key: item.key!,
          width: item.width!,
          height: item.height!,
          placeholderHash: item.placeholderHash,
          tags: item.tags,
          venueLocationId: item.locationId,
        ),
      );
      final photo = res.data;
      if (!res.success || photo == null) {
        await _attachRejected(localId, _codeOf(res), emit);
        return;
      }
      final existing = _photos.indexWhere((p) => p.id == photo.id);
      if (existing >= 0) {
        _photos[existing] = photo;
      } else {
        _photos.add(photo);
      }
      _changed = true;
      _update(localId, (u) => u.copyWith(status: GalleryUploadStatus.done));
      emit(_snapshot());
    } catch (error) {
      final apiError = VenueApiError.from(error);
      if (apiError.isAlreadyAttached) {
        _changed = true;
        _update(localId, (u) => u.copyWith(status: GalleryUploadStatus.done));
        await _fetch();
        emit(_snapshot());
        return;
      }
      await _attachRejected(localId, apiError.code, emit);
    }
  }

  static const _failsQueue = {
    VenueErrorCodes.galleryLimitReached,
    VenueErrorCodes.galleryRateLimited,
  };

  Future<void> _uploadRejected(
    int localId,
    String? code,
    Emitter<ManageGalleryState> emit,
  ) async {
    if (!_failsQueue.contains(code)) {
      _failItem(localId, code, emit);
      return;
    }
    for (var i = 0; i < _uploads.length; i++) {
      final u = _uploads[i];
      if (u.localId == localId || u.status == GalleryUploadStatus.queued) {
        _uploads[i] = u.copyWith(
          status: GalleryUploadStatus.failed,
          errorCode: () => code,
        );
      }
    }
    _noticeFor(code);
    if (code == VenueErrorCodes.galleryLimitReached) await _fetch();
    emit(_snapshot());
  }

  Future<void> _attachRejected(
    int localId,
    String? code,
    Emitter<ManageGalleryState> emit,
  ) async {
    const reupload = {'GALLERY_OBJECT_MISSING', 'GALLERY_KEY_INVALID'};
    if (reupload.contains(code)) {
      _update(localId, (u) => u.copyWith(key: () => null));
    }
    final branchGone = code == VenueErrorCodes.branchNotFound;
    if (branchGone) {
      _update(localId, (u) => u.copyWith(locationId: () => null));
    }
    if (code == VenueErrorCodes.galleryLimitReached) await _fetch();
    _failItem(localId, code, emit, branchCleared: branchGone);
  }

  void _failItem(
    int localId,
    String? code,
    Emitter<ManageGalleryState> emit, {
    bool branchCleared = false,
  }) {
    _update(
      localId,
      (u) =>
          u.copyWith(status: GalleryUploadStatus.failed, errorCode: () => code),
    );
    _noticeFor(code, branchCleared: branchCleared);
    emit(_snapshot());
  }

  GalleryUploadItem _item(int localId) =>
      _uploads.firstWhere((u) => u.localId == localId);

  void _update(
    int localId,
    GalleryUploadItem Function(GalleryUploadItem) change,
  ) {
    final i = _uploads.indexWhere((u) => u.localId == localId);
    if (i >= 0) _uploads[i] = change(_uploads[i]);
  }

  Future<void> _onEdited(
    GalleryPhotoEdited event,
    Emitter<ManageGalleryState> emit,
  ) async {
    if (!canManage) return;
    if (event.tags == null && event.venueLocationId == null) return;
    await _mutate(emit, () async {
      final res = await _api.businessUpdateGalleryPhoto(
        venueId,
        event.photoId,
        UpdateGalleryPhotoRequest(
          tags: event.tags == null
              ? null
              : knownTags(event.tags!).take(kGalleryMaxTagsPerPhoto).toList(),
          venueLocationId: event.venueLocationId,
        ),
      );
      final photo = _require(res);
      final i = _photos.indexWhere((p) => p.id == photo.id);
      if (i >= 0) _photos[i] = photo;
    });
  }

  Future<void> _onReorder(
    GalleryReorderCommitted event,
    Emitter<ManageGalleryState> emit,
  ) async {
    if (!canManage) return;
    final current = [for (final p in _photos) p.id];
    if (_sameOrder(current, event.photoIds)) return;
    final before = List<GalleryPhotoDto>.of(_photos);
    final byId = {for (final p in _photos) p.id: p};
    _photos
      ..clear()
      ..addAll([for (final id in event.photoIds) ?byId[id]]);
    await _mutate(
      emit,
      () async {
        final res = await _api.businessReorderGallery(
          venueId,
          ReorderGalleryRequest(photoIds: event.photoIds),
        );
        _applyList(_require(res));
      },
      onError: () => _photos
        ..clear()
        ..addAll(before),
    );
  }

  Future<void> _onDeleted(
    GalleryPhotoDeleted event,
    Emitter<ManageGalleryState> emit,
  ) async {
    if (!canManage) return;
    await _mutate(emit, () async {
      final res = await _api.businessDeleteGalleryPhoto(venueId, event.photoId);
      if (!res.success) throw _ApiFailure(_codeOf(res));
      _photos.removeWhere((p) => p.id == event.photoId);
    });
  }

  Future<void> _mutate(
    Emitter<ManageGalleryState> emit,
    Future<void> Function() call, {
    void Function()? onError,
  }) async {
    _busy = true;
    emit(_snapshot());
    try {
      await call();
      _changed = true;
    } catch (error) {
      final code = error is _ApiFailure
          ? error.code
          : VenueApiError.from(error).code;
      onError?.call();
      _noticeFor(code);
      if (code == VenueErrorCodes.galleryOrderMismatch ||
          code == VenueErrorCodes.photoNotFound) {
        _changed = true;
        await _fetch();
      }
    }
    _busy = false;
    emit(_snapshot());
  }

  T _require<T>(ApiResponse<T> res) {
    final data = res.data;
    if (!res.success || data == null) throw _ApiFailure(_codeOf(res));
    return data;
  }

  static String? _codeOf(ApiResponse<Object?> res) =>
      VenueApiError.fromMessage(res.error).code;

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _noticeFor(String? code, {bool branchCleared = false}) =>
      _notice = ManageGalleryNotice(
        serial: ++_noticeSerial,
        code: code,
        branchCleared: branchCleared,
      );

  ManageGalleryState _snapshot({ManageGalleryStatus? status}) =>
      ManageGalleryState(
        status: status ?? (_loaded ? ManageGalleryStatus.ready : state.status),
        photos: List.unmodifiable(_photos),
        maxPhotos: _maxPhotos,
        uploads: List.unmodifiable(_uploads),
        remaining: _remaining,
        busy: _busy,
        changed: _changed,
        notice: _notice,
      );
}

class _ApiFailure implements Exception {
  final String? code;
  const _ApiFailure(this.code);
}
