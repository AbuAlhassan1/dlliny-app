import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';

abstract class VenueErrorCodes {
  static const hoursOverlap = 'HOURS_OVERLAP';
  static const hoursTooManyIntervals = 'HOURS_TOO_MANY_INTERVALS';
  static const hoursEmptyInterval = 'HOURS_EMPTY_INTERVAL';
  static const hoursIntervalTooShort = 'HOURS_INTERVAL_TOO_SHORT';
  static const hoursInvalidTime = 'HOURS_INVALID_TIME';
  static const hoursDaysIncomplete = 'HOURS_DAYS_INCOMPLETE';
  static const hoursKindMismatch = 'HOURS_KIND_MISMATCH';
  static const hoursRamadanConflict = 'HOURS_RAMADAN_CONFLICT';

  static const hoursIntervalIncomplete = 'HOURS_INTERVAL_INCOMPLETE';
  static const statusReopenDateInvalid = 'STATUS_REOPEN_DATE_INVALID';
  static const statusReopenDateNotAllowed = 'STATUS_REOPEN_DATE_NOT_ALLOWED';
  static const statusRequired = 'STATUS_REQUIRED';
  static const branchNotFound = 'BRANCH_NOT_FOUND';

  static const galleryLimitReached = 'GALLERY_LIMIT_REACHED';
  static const galleryOrderMismatch = 'GALLERY_ORDER_MISMATCH';

  static const galleryDuplicateKey = 'GALLERY_DUPLICATE_KEY';
  static const galleryUnsupportedType = 'GALLERY_UNSUPPORTED_TYPE';
  static const galleryInvalidContentType = 'GALLERY_INVALID_CONTENT_TYPE';
  static const galleryTooLarge = 'GALLERY_TOO_LARGE';
  static const galleryInvalidLength = 'GALLERY_INVALID_LENGTH';
  static const galleryRateLimited = 'GALLERY_RATE_LIMITED';
  static const photoNotFound = 'PHOTO_NOT_FOUND';

  static const galleryDimensionsInvalid = 'GALLERY_DIMENSIONS_INVALID';
}

final RegExp _codePrefix = RegExp(r'^([A-Z][A-Z0-9_]*):\s*');

class VenueApiError {
  final int? statusCode;

  final String? message;

  final String? code;

  final String? detail;

  const VenueApiError({this.statusCode, this.message, this.code, this.detail});

  factory VenueApiError.from(Object error) {
    if (error is VenueApiError) return error;
    if (error is DioException) {
      final data = error.response?.data;
      final message = data is Map && data['error'] is String
          ? data['error'] as String
          : null;
      return VenueApiError.fromMessage(
        message,
        statusCode: error.response?.statusCode,
      );
    }
    if (error is String) return VenueApiError.fromMessage(error);
    return const VenueApiError();
  }

  factory VenueApiError.fromMessage(String? message, {int? statusCode}) {
    final m = message == null ? null : _codePrefix.firstMatch(message);
    if (m == null) {
      return VenueApiError(statusCode: statusCode, message: message);
    }
    var detail = message!.substring(m.end);
    final next = RegExp(r', [A-Z][A-Z0-9_]*:').firstMatch(detail);
    if (next != null) detail = detail.substring(0, next.start);
    return VenueApiError(
      statusCode: statusCode,
      message: message,
      code: m.group(1),
      detail: detail.trim().isEmpty ? null : detail.trim(),
    );
  }

  bool get isAlreadyAttached => code == VenueErrorCodes.galleryDuplicateKey;
}

String? serverErrorCode(String? message) =>
    VenueApiError.fromMessage(message).code;

String hoursEditorErrorText(String? code, {String? detail}) {
  switch (code) {
    case VenueErrorCodes.hoursOverlap:
      final text = LocaleKeys.manage_venue_hours_editor_errors_overlap.tr(
        namedArgs: {'detail': detail ?? ''},
      );
      return detail == null ? text.replaceFirst(RegExp(r'\s*:\s*$'), '') : text;
    case VenueErrorCodes.hoursTooManyIntervals:
      return LocaleKeys.manage_venue_hours_editor_errors_too_many_intervals
          .tr();
    case VenueErrorCodes.hoursEmptyInterval:
      return LocaleKeys.manage_venue_hours_editor_errors_empty_interval.tr();
    case VenueErrorCodes.hoursIntervalTooShort:
      return LocaleKeys.manage_venue_hours_editor_errors_too_short.tr();
    case VenueErrorCodes.hoursInvalidTime:
      return LocaleKeys.manage_venue_hours_editor_errors_invalid_time.tr();
    case VenueErrorCodes.statusReopenDateInvalid:
    case VenueErrorCodes.statusReopenDateNotAllowed:
      return LocaleKeys.manage_venue_hours_editor_errors_reopen_date_invalid
          .tr();
    case VenueErrorCodes.hoursIntervalIncomplete:
      return LocaleKeys.manage_venue_hours_editor_errors_interval_incomplete
          .tr();
    default:
      return LocaleKeys.manage_venue_hours_editor_errors_generic.tr();
  }
}

String galleryManagerErrorText(String? code, {int? maxPhotos}) {
  switch (code) {
    case VenueErrorCodes.galleryLimitReached:
      return LocaleKeys.manage_venue_gallery_manager_limit_reached.tr(
        namedArgs: {'max': '${maxPhotos ?? kGalleryMaxPhotos}'},
      );
    case VenueErrorCodes.galleryUnsupportedType:
    case VenueErrorCodes.galleryInvalidContentType:
      return LocaleKeys.manage_venue_gallery_manager_unsupported_type.tr();
    case VenueErrorCodes.galleryTooLarge:
    case VenueErrorCodes.galleryInvalidLength:
      return LocaleKeys.manage_venue_gallery_manager_too_large.tr();
    case VenueErrorCodes.galleryDimensionsInvalid:
      return LocaleKeys.manage_venue_gallery_manager_dimensions_invalid.tr();
    case VenueErrorCodes.galleryRateLimited:
      return LocaleKeys.manage_venue_gallery_manager_rate_limited.tr();
    case VenueErrorCodes.branchNotFound:
      return LocaleKeys.manage_venue_gallery_manager_branch_not_found.tr();
    default:
      return LocaleKeys.common_error_generic.tr();
  }
}
