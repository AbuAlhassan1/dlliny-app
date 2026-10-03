import 'package:hangout/domain/dto/request/venue_hours_requests.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';

const int kMaxIntervalsPerDay = 4;
const int kMinIntervalMinutes = 15;
const int kMaxReopenDaysAhead = 365;

const int _dayMinutes = 1440;
const int _weekMinutes = 7 * _dayMinutes;
const List<String> _dayNames = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

final RegExp _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
final RegExp _date = RegExp(r'^\d{4}-\d{2}-\d{2}$');

class HoursSegmentRef {
  final int dayOfWeek;

  final String? opens;
  final String? closes;

  const HoursSegmentRef(this.dayOfWeek, {this.opens, this.closes});

  bool get isAllDay => opens == null;

  String get label => isAllDay
      ? '${_dayNames[dayOfWeek]} 24h'
      : '${_dayNames[dayOfWeek]} $opens–$closes';

  @override
  bool operator ==(Object other) =>
      other is HoursSegmentRef &&
      other.dayOfWeek == dayOfWeek &&
      other.opens == opens &&
      other.closes == closes;

  @override
  int get hashCode => Object.hash(dayOfWeek, opens, closes);

  @override
  String toString() => label;
}

class HoursValidationError {
  final String code;

  final String detail;

  final int? dayOfWeek;

  final List<HoursSegmentRef> conflict;

  const HoursValidationError(
    this.code,
    this.detail, {
    this.dayOfWeek,
    this.conflict = const [],
  });

  @override
  String toString() => '$code: $detail';
}

HoursValidationError? validateWeeklySchedule(List<HoursDayInput>? days) {
  if (days == null || days.length != 7) {
    return const HoursValidationError(
      VenueErrorCodes.hoursDaysIncomplete,
      'exactly 7 days required',
    );
  }
  final seen = <int>{};
  for (final day in days) {
    if (day.dayOfWeek < 0 || day.dayOfWeek > 6 || !seen.add(day.dayOfWeek)) {
      return const HoursValidationError(
        VenueErrorCodes.hoursDaysIncomplete,
        'each dayOfWeek 0..6 exactly once',
      );
    }
  }

  final segments = <_Segment>[];
  for (final day in days) {
    final dow = day.dayOfWeek;
    final name = _dayNames[dow];
    final kind = _parseKind(day.kind);
    if (kind == null) {
      return HoursValidationError(
        'HOURS_INVALID_KIND',
        'kind must be CLOSED, OPEN_24H or HOURS',
        dayOfWeek: dow,
      );
    }
    final intervals = day.intervals;
    if (kind != HoursDayKind.hours && intervals.isNotEmpty) {
      return HoursValidationError(
        VenueErrorCodes.hoursKindMismatch,
        '$name is ${kind.wire} and must carry no intervals',
        dayOfWeek: dow,
      );
    }
    if (kind == HoursDayKind.hours && intervals.isEmpty) {
      return HoursValidationError(
        VenueErrorCodes.hoursKindMismatch,
        '$name is HOURS and needs at least one interval',
        dayOfWeek: dow,
      );
    }
    if (intervals.length > kMaxIntervalsPerDay) {
      return HoursValidationError(
        VenueErrorCodes.hoursTooManyIntervals,
        'at most $kMaxIntervalsPerDay intervals per day ($name)',
        dayOfWeek: dow,
      );
    }
    for (final iv in intervals) {
      if (iv.opens.isEmpty || iv.closes.isEmpty) {
        return HoursValidationError(
          VenueErrorCodes.hoursIntervalIncomplete,
          'pick both times of every interval on $name',
          dayOfWeek: dow,
        );
      }
      if (!_time.hasMatch(iv.opens) || !_time.hasMatch(iv.closes)) {
        return HoursValidationError(
          VenueErrorCodes.hoursInvalidTime,
          'times must be HH:mm (00:00–23:59) on $name',
          dayOfWeek: dow,
        );
      }
    }

    if (kind == HoursDayKind.closed) continue;
    if (kind == HoursDayKind.open24h) {
      segments.add(
        _Segment(
          dow * _dayMinutes,
          dow * _dayMinutes + _dayMinutes,
          HoursSegmentRef(dow),
        ),
      );
      continue;
    }
    for (final iv in intervals) {
      final open = _minuteOfDay(iv.opens);
      final close = _minuteOfDay(iv.closes);
      final ref = HoursSegmentRef(dow, opens: iv.opens, closes: iv.closes);
      if (open == close) {
        return HoursValidationError(
          VenueErrorCodes.hoursEmptyInterval,
          '${ref.label} opens and closes at the same time (use OPEN_24H)',
          dayOfWeek: dow,
        );
      }
      final duration = close > open ? close - open : _dayMinutes - open + close;
      if (duration < kMinIntervalMinutes) {
        return HoursValidationError(
          VenueErrorCodes.hoursIntervalTooShort,
          '${ref.label} is shorter than $kMinIntervalMinutes minutes',
          dayOfWeek: dow,
        );
      }
      final start = dow * _dayMinutes + open;
      segments.add(_Segment(start, start + duration, ref));
    }
  }
  return _checkNoOverlap(segments);
}

(int start, int length)? rangeMinutes(String opens, String closes) {
  final open = _minuteOfDay(opens);
  final close = _minuteOfDay(closes);
  if (open == close) return null;
  return (open, close > open ? close - open : _dayMinutes - open + close);
}

String? rangeErrorCode(String opens, String closes) {
  if (!_time.hasMatch(opens) || !_time.hasMatch(closes)) {
    return VenueErrorCodes.hoursInvalidTime;
  }
  final range = rangeMinutes(opens, closes);
  if (range == null) return VenueErrorCodes.hoursEmptyInterval;
  return range.$2 < kMinIntervalMinutes
      ? VenueErrorCodes.hoursIntervalTooShort
      : null;
}

HoursValidationError? checkScheduleRequest({
  required bool hasRegular,
  required bool hasRamadan,
  required bool removeRamadan,
}) {
  if (!hasRegular) {
    return const HoursValidationError(
      'HOURS_REGULAR_REQUIRED',
      'regular schedule is required',
    );
  }
  if (hasRamadan && removeRamadan) {
    return const HoursValidationError(
      VenueErrorCodes.hoursRamadanConflict,
      'send either a ramadan schedule or removeRamadan: true, not both',
    );
  }
  return null;
}

HoursValidationError? checkBranchScheduleRequest({
  required String mode,
  required bool hasRegular,
  required bool hasRamadan,
  required bool removeRamadan,
}) {
  if (mode != 'OWN' && mode != 'INHERIT') {
    return const HoursValidationError(
      'HOURS_INVALID_MODE',
      'mode must be OWN or INHERIT',
    );
  }
  if (mode == 'INHERIT') {
    if (hasRegular || hasRamadan || removeRamadan) {
      return const HoursValidationError(
        'HOURS_INHERIT_WITH_SCHEDULE',
        'mode INHERIT carries no schedules',
      );
    }
    return null;
  }
  return checkScheduleRequest(
    hasRegular: hasRegular,
    hasRamadan: hasRamadan,
    removeRamadan: removeRamadan,
  );
}

HoursValidationError? validateOperatingStatus(
  String? status,
  String? reopensOn,
  String today,
) {
  if (status == null) {
    return const HoursValidationError(
      VenueErrorCodes.statusRequired,
      'status is required',
    );
  }
  if (status != 'OPEN' &&
      status != 'TEMPORARILY_CLOSED' &&
      status != 'PERMANENTLY_CLOSED') {
    return const HoursValidationError(
      'STATUS_INVALID',
      'status must be OPEN, TEMPORARILY_CLOSED or PERMANENTLY_CLOSED',
    );
  }
  if (reopensOn == null) return null;
  if (status != 'TEMPORARILY_CLOSED') {
    return const HoursValidationError(
      VenueErrorCodes.statusReopenDateNotAllowed,
      'reopensOn is only allowed with TEMPORARILY_CLOSED',
    );
  }
  final date = _date.hasMatch(reopensOn) ? _strictDate(reopensOn) : null;
  final base = parseYmd(today);
  if (date == null || base == null) {
    return const HoursValidationError(
      VenueErrorCodes.statusReopenDateInvalid,
      'reopensOn must be a valid YYYY-MM-DD date',
    );
  }
  if (!date.isAfter(base) ||
      date.isAfter(base.add(const Duration(days: kMaxReopenDaysAhead)))) {
    return HoursValidationError(
      VenueErrorCodes.statusReopenDateInvalid,
      'reopensOn must be after $today and at most $kMaxReopenDaysAhead days ahead',
    );
  }
  return null;
}

HoursValidationError? validateBranchOperatingStatus(
  String mode,
  String? status,
  String? reopensOn,
  String today,
) {
  if (mode != 'OWN' && mode != 'INHERIT') {
    return const HoursValidationError(
      'STATUS_INVALID_MODE',
      'mode must be OWN or INHERIT',
    );
  }
  if (mode == 'INHERIT') {
    if (status != null || reopensOn != null) {
      return const HoursValidationError(
        'STATUS_INHERIT_WITH_VALUE',
        'mode INHERIT carries no status or reopensOn',
      );
    }
    return null;
  }
  return validateOperatingStatus(status, reopensOn, today);
}

class _Segment {
  final int start;
  final int end;
  final HoursSegmentRef ref;
  const _Segment(this.start, this.end, this.ref);
}

HoursValidationError? _checkNoOverlap(List<_Segment> segments) {
  final flat = <_Segment>[];
  for (final s in segments) {
    if (s.end > _weekMinutes) {
      flat
        ..add(_Segment(s.start, _weekMinutes, s.ref))
        ..add(_Segment(0, s.end - _weekMinutes, s.ref));
    } else {
      flat.add(s);
    }
  }
  flat.sort((a, b) {
    final byStart = a.start.compareTo(b.start);
    return byStart != 0 ? byStart : a.end.compareTo(b.end);
  });
  for (var i = 1; i < flat.length; i++) {
    final prev = flat[i - 1];
    final next = flat[i];
    if (next.start < prev.end) {
      return HoursValidationError(
        VenueErrorCodes.hoursOverlap,
        '${prev.ref.label} overlaps ${next.ref.label}',
        dayOfWeek: prev.ref.dayOfWeek,
        conflict: [prev.ref, next.ref],
      );
    }
  }
  return null;
}

HoursDayKind? _parseKind(String kind) => switch (kind) {
  'CLOSED' => HoursDayKind.closed,
  'OPEN_24H' => HoursDayKind.open24h,
  'HOURS' => HoursDayKind.hours,
  _ => null,
};

int _minuteOfDay(String hhmm) =>
    int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3, 5));

DateTime? _strictDate(String ymd) {
  final d = parseYmd(ymd);
  if (d == null || formatYmd(d) != ymd) return null;
  return d;
}
