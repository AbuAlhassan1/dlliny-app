import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';

import '../../../helpers/locale_test_helper.dart';
import '../../../helpers/test_harness.dart';

void main() {
  setUpAll(() => loadTestLocale('ar'));

  group('VenueApiError', () {
    test('splits "CODE: detail"', () {
      final e = VenueApiError.fromMessage(
        'HOURS_OVERLAP: Sun 09:00–13:00 overlaps Sun 12:00–14:00',
        statusCode: 400,
      );
      expect(e.code, 'HOURS_OVERLAP');
      expect(e.detail, 'Sun 09:00–13:00 overlaps Sun 12:00–14:00');
      expect(e.statusCode, 400);
    });

    test('joined bean-validation messages: the first code wins', () {
      final e = VenueApiError.fromMessage(
        'HOURS_TOO_MANY_INTERVALS: at most 4 intervals per day, '
        'HOURS_INVALID_TIME: opens must be HH:mm (00:00–23:59)',
      );
      expect(e.code, 'HOURS_TOO_MANY_INTERVALS');
      expect(e.detail, 'at most 4 intervals per day');
    });

    test('messages without a CODE: prefix carry no code', () {
      for (final m in [
        'Access denied',
        'Venue not found',
        "Invalid value for 'regular.days[0].dayOfWeek'",
        "Missing required parameter 'contentType'",
      ]) {
        expect(VenueApiError.fromMessage(m).code, isNull, reason: m);
      }
      expect(
        serverErrorCode('GONE: use /api/v1/business/venues/v/gallery'),
        'GONE',
      );
      expect(serverErrorCode(null), isNull);
    });

    test(
      'from a DioException body, a status-only failure, or anything else',
      () {
        final withBody = VenueApiError.from(
          dioErrorWithMessage(
            'GALLERY_LIMIT_REACHED: at most 24 photos',
            statusCode: 409,
          ),
        );
        expect(withBody.code, VenueErrorCodes.galleryLimitReached);
        expect(withBody.statusCode, 409);

        final noBody = VenueApiError.from(dioErrorWithStatus(500));
        expect(noBody.code, isNull);
        expect(noBody.statusCode, 500);

        final stringBody = VenueApiError.from(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            response: Response<String>(
              requestOptions: RequestOptions(path: '/'),
              statusCode: 502,
              data: '<html>Bad gateway</html>',
            ),
          ),
        );
        expect(stringBody.code, isNull);
        expect(stringBody.statusCode, 502);

        expect(
          VenueApiError.from(const FormatException('bad json')).code,
          isNull,
        );
        expect(
          VenueApiError.from(
            'STATUS_REQUIRED: mode OWN requires a status',
          ).code,
          'STATUS_REQUIRED',
        );
      },
    );

    test('GALLERY_DUPLICATE_KEY means "already attached", not a failure', () {
      expect(
        VenueApiError.from(
          dioErrorWithMessage(
            'GALLERY_DUPLICATE_KEY: already attached',
            statusCode: 409,
          ),
        ).isAlreadyAttached,
        isTrue,
      );
      expect(
        VenueApiError.fromMessage('GALLERY_LIMIT_REACHED: x').isAlreadyAttached,
        isFalse,
      );
    });
  });

  test('hoursEditorErrorText maps the spec §6.5 codes', () {
    expect(
      hoursEditorErrorText(
        'HOURS_OVERLAP',
        detail: 'Sun 09:00–13:00 overlaps Sun 12:00–14:00',
      ),
      'الفترات متداخلة: Sun 09:00–13:00 overlaps Sun 12:00–14:00',
    );
    expect(hoursEditorErrorText('HOURS_OVERLAP'), 'الفترات متداخلة');
    expect(
      hoursEditorErrorText('HOURS_TOO_MANY_INTERVALS'),
      'أربع فترات كحد أقصى لكل يوم',
    );
    expect(
      hoursEditorErrorText('HOURS_EMPTY_INTERVAL'),
      'وقت الفتح والإغلاق يجب أن يختلفا — اختر 24 ساعة',
    );
    expect(
      hoursEditorErrorText('HOURS_INTERVAL_TOO_SHORT'),
      'أقل مدة للفترة 15 دقيقة',
    );
    expect(hoursEditorErrorText('HOURS_INVALID_TIME'), 'وقت غير صحيح');
    for (final code in [
      'STATUS_REOPEN_DATE_INVALID',
      'STATUS_REOPEN_DATE_NOT_ALLOWED',
    ]) {
      expect(
        hoursEditorErrorText(code),
        'تاريخ العودة يجب أن يكون بعد اليوم وخلال سنة',
        reason: code,
      );
    }
    expect(
      hoursEditorErrorText(VenueErrorCodes.hoursIntervalIncomplete),
      'اختر وقت الفتح والإغلاق لكل يوم مفتوح',
    );
    for (final code in [
      'STATUS_REQUIRED',
      'HOURS_RAMADAN_CONFLICT',
      'BRANCH_NOT_FOUND',
      null,
    ]) {
      expect(
        hoursEditorErrorText(code),
        'تعذر حفظ الأوقات، حاول مرة ثانية',
        reason: '$code',
      );
    }
  });

  test('galleryManagerErrorText maps the spec §6.5 codes', () {
    expect(
      galleryManagerErrorText('GALLERY_LIMIT_REACHED'),
      'وصلت للحد الأقصى (24 صورة)',
    );
    expect(
      galleryManagerErrorText('GALLERY_LIMIT_REACHED', maxPhotos: 40),
      'وصلت للحد الأقصى (40 صورة)',
    );
    for (final code in [
      'GALLERY_UNSUPPORTED_TYPE',
      'GALLERY_INVALID_CONTENT_TYPE',
    ]) {
      expect(
        galleryManagerErrorText(code),
        'صيغة غير مدعومة (JPG أو PNG أو WebP فقط)',
        reason: code,
      );
    }
    for (final code in ['GALLERY_TOO_LARGE', 'GALLERY_INVALID_LENGTH']) {
      expect(
        galleryManagerErrorText(code),
        'حجم الصورة أكبر من 10 ميغابايت',
        reason: code,
      );
    }
    expect(
      galleryManagerErrorText('GALLERY_DIMENSIONS_INVALID'),
      'الصورة طويلة أو عريضة جداً (5:1 كحد أقصى)',
    );
    expect(
      galleryManagerErrorText('GALLERY_RATE_LIMITED'),
      'رفعت صوراً كثيرة، حاول بعد قليل',
    );
    expect(
      galleryManagerErrorText('BRANCH_NOT_FOUND'),
      'الفرع المختار لم يعد متاحاً',
    );
    for (final code in ['GALLERY_ORDER_MISMATCH', 'PHOTO_NOT_FOUND', null]) {
      expect(
        galleryManagerErrorText(code),
        'حصل خطأ، حاول مرة ثانية',
        reason: '$code',
      );
    }
  });
}
