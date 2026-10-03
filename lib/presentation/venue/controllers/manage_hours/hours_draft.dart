import 'package:flutter/foundation.dart';
import 'package:hangout/domain/dto/request/venue_hours_requests.dart';
import 'package:hangout/domain/dto/response/business_venue_hours_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/utils/hours_editor_validation.dart';

@immutable
class DraftInterval {
  final String? opens;
  final String? closes;

  const DraftInterval({this.opens, this.closes});

  static const DraftInterval empty = DraftInterval();

  bool get isComplete => opens != null && closes != null;

  bool get overnight => isComplete && closes!.compareTo(opens!) <= 0;

  @override
  bool operator ==(Object other) =>
      other is DraftInterval && other.opens == opens && other.closes == closes;

  @override
  int get hashCode => Object.hash(opens, closes);
}

@immutable
class DraftDay {
  final int dayOfWeek;
  final HoursDayKind kind;
  final List<DraftInterval> intervals;

  const DraftDay({
    required this.dayOfWeek,
    required this.kind,
    this.intervals = const [],
  });

  factory DraftDay.startingHours(int dayOfWeek) => DraftDay(
    dayOfWeek: dayOfWeek,
    kind: HoursDayKind.hours,
    intervals: const [DraftInterval.empty],
  );

  List<DraftInterval> get effectiveIntervals =>
      kind == HoursDayKind.hours ? intervals : const [];

  bool get isComplete =>
      kind != HoursDayKind.hours ||
      (intervals.isNotEmpty && intervals.every((i) => i.isComplete));

  DraftDay copyWith({HoursDayKind? kind, List<DraftInterval>? intervals}) =>
      DraftDay(
        dayOfWeek: dayOfWeek,
        kind: kind ?? this.kind,
        intervals: intervals ?? this.intervals,
      );

  DraftDay onDay(int dow) =>
      DraftDay(dayOfWeek: dow, kind: kind, intervals: intervals);

  HoursDayInput toInput() => HoursDayInput(
    dayOfWeek: dayOfWeek,
    kind: kind.wire,
    intervals: [
      for (final i in effectiveIntervals)
        HoursIntervalInput(opens: i.opens ?? '', closes: i.closes ?? ''),
    ],
  );

  DayScheduleDto toDto() => DayScheduleDto(
    dayOfWeek: dayOfWeek,
    kind: kind,
    intervals: [
      for (final i in effectiveIntervals.where((i) => i.isComplete))
        HoursIntervalDto(
          opens: i.opens!,
          closes: i.closes!,
          overnight: i.overnight,
        ),
    ],
  );

  @override
  bool operator ==(Object other) =>
      other is DraftDay &&
      other.dayOfWeek == dayOfWeek &&
      other.kind == kind &&
      listEquals(other.effectiveIntervals, effectiveIntervals);

  @override
  int get hashCode =>
      Object.hash(dayOfWeek, kind, Object.hashAll(effectiveIntervals));
}

enum ApplyRangeMode {
  replace,

  add,
}

enum ApplyConflictKind {
  overlap,

  tooMany,
}

@immutable
class ApplyRangeConflict {
  final ApplyConflictKind kind;

  final HoursSegmentRef? other;

  const ApplyRangeConflict.overlap(HoursSegmentRef this.other)
    : kind = ApplyConflictKind.overlap;

  const ApplyRangeConflict.tooMany()
    : kind = ApplyConflictKind.tooMany,
      other = null;

  @override
  bool operator ==(Object other) =>
      other is ApplyRangeConflict &&
      other.kind == kind &&
      other.other == this.other;

  @override
  int get hashCode => Object.hash(kind, other);

  @override
  String toString() => other == null ? kind.name : '${kind.name}($other)';
}

@immutable
class DraftWeek {
  final List<DraftDay> days;

  const DraftWeek._(this.days);

  factory DraftWeek.fromDto(WeeklyScheduleDto dto) => DraftWeek._(
    List.unmodifiable([
      for (var dow = 0; dow < 7; dow++)
        () {
          final d = dto.day(dow);
          if (d == null) {
            return DraftDay(dayOfWeek: dow, kind: HoursDayKind.closed);
          }
          return DraftDay(
            dayOfWeek: dow,
            kind: d.kind,
            intervals: List.unmodifiable([
              for (final i in d.intervals)
                DraftInterval(opens: i.opens, closes: i.closes),
            ]),
          );
        }(),
    ]),
  );

  factory DraftWeek.starting() => DraftWeek._(
    List.unmodifiable([
      for (var dow = 0; dow < 7; dow++) DraftDay.startingHours(dow),
    ]),
  );

  DraftDay day(int dow) => days[dow];

  DraftWeek withDay(DraftDay day) => DraftWeek._(
    List.unmodifiable([
      for (final d in days) d.dayOfWeek == day.dayOfWeek ? day : d,
    ]),
  );

  DraftWeek copyDayToAll(int dow) {
    final source = days[dow];
    return DraftWeek._(
      List.unmodifiable([for (var d = 0; d < 7; d++) source.onDay(d)]),
    );
  }

  DraftWeek applyToDays(
    DraftInterval range,
    Set<int> days,
    ApplyRangeMode mode,
  ) {
    assert(range.isComplete);
    return DraftWeek._(
      List.unmodifiable([
        for (final d in this.days)
          days.contains(d.dayOfWeek) ? _withRange(d, range, mode) : d,
      ]),
    );
  }

  static DraftDay _withRange(
    DraftDay day,
    DraftInterval range,
    ApplyRangeMode mode,
  ) => day.copyWith(
    kind: HoursDayKind.hours,
    intervals: List.unmodifiable(
      [..._keptBy(day, mode), range]
        ..sort((a, b) => a.opens!.compareTo(b.opens!)),
    ),
  );

  static Iterable<DraftInterval> _keptBy(DraftDay day, ApplyRangeMode mode) =>
      mode == ApplyRangeMode.add && day.kind == HoursDayKind.hours
      ? day.intervals.where((i) => i.isComplete)
      : const <DraftInterval>[];

  Map<int, ApplyRangeConflict> applyConflicts(
    DraftInterval range,
    Set<int> days,
    ApplyRangeMode mode,
  ) {
    final span = rangeMinutes(range.opens!, range.closes!);
    assert(span != null, 'opens == closes is not a range');
    if (span == null) return const {};

    List<_WeekSpan> keptOf(DraftDay day) {
      final dow = day.dayOfWeek;
      if (days.contains(dow)) {
        return [for (final iv in _keptBy(day, mode)) ?_WeekSpan.of(dow, iv)];
      }
      if (day.kind == HoursDayKind.open24h) return [_WeekSpan.allDay(dow)];
      return [for (final iv in day.effectiveIntervals) ?_WeekSpan.of(dow, iv)];
    }

    final kept = [for (final day in this.days) keptOf(day)];

    final conflicts = <int, ApplyRangeConflict>{};
    for (final dow in days) {
      if (_keptBy(this.days[dow], mode).length + 1 > kMaxIntervalsPerDay) {
        conflicts[dow] = const ApplyRangeConflict.tooMany();
        continue;
      }
      final start = dow * _dayMinutes + span.$1;
      final end = start + span.$2;
      final hit = [
        dow,
        (dow + 6) % 7,
        (dow + 1) % 7,
      ].expand((d) => kept[d]).where((s) => s.overlaps(start, end)).firstOrNull;
      if (hit != null) conflicts[dow] = ApplyRangeConflict.overlap(hit.ref);
    }
    return conflicts;
  }

  bool get isComplete => days.every((d) => d.isComplete);

  Set<int> get incompleteDays => {
    for (final d in days)
      if (!d.isComplete) d.dayOfWeek,
  };

  bool get allClosed => days.every((d) => d.kind == HoursDayKind.closed);

  WeeklyScheduleInput toInput() =>
      WeeklyScheduleInput(days: [for (final d in days) d.toInput()]);

  WeeklyScheduleDto toDto() =>
      WeeklyScheduleDto(days: [for (final d in days) d.toDto()]);

  @override
  bool operator ==(Object other) =>
      other is DraftWeek && listEquals(other.days, days);

  @override
  int get hashCode => Object.hashAll(days);
}

const int _dayMinutes = 1440;
const int _weekMinutes = 7 * _dayMinutes;

class _WeekSpan {
  final int start;
  final int end;
  final HoursSegmentRef ref;

  const _WeekSpan(this.start, this.end, this.ref);

  _WeekSpan.allDay(int dow)
    : start = dow * _dayMinutes,
      end = (dow + 1) * _dayMinutes,
      ref = HoursSegmentRef(dow);

  static _WeekSpan? of(int dow, DraftInterval iv) {
    final m = iv.isComplete ? rangeMinutes(iv.opens!, iv.closes!) : null;
    if (m == null) return null;
    final start = dow * _dayMinutes + m.$1;
    return _WeekSpan(
      start,
      start + m.$2,
      HoursSegmentRef(dow, opens: iv.opens, closes: iv.closes),
    );
  }

  bool overlaps(int from, int to) {
    for (final shift in const [-_weekMinutes, 0, _weekMinutes]) {
      if (from < end + shift && start + shift < to) return true;
    }
    return false;
  }
}

@immutable
class HoursDraft {
  final bool own;

  final DraftWeek? regular;

  final DraftWeek? ramadan;

  const HoursDraft({required this.own, this.regular, this.ramadan});

  HoursDraft copyWith({
    bool? own,
    DraftWeek? regular,
    DraftWeek? ramadan,
    bool clearRegular = false,
    bool clearRamadan = false,
  }) => HoursDraft(
    own: own ?? this.own,
    regular: clearRegular ? null : (regular ?? this.regular),
    ramadan: clearRamadan ? null : (ramadan ?? this.ramadan),
  );

  DraftWeek? week(HoursSeason season) =>
      season == HoursSeason.ramadan ? ramadan : regular;

  HoursDraft withWeek(HoursSeason season, DraftWeek week) =>
      season == HoursSeason.ramadan
      ? copyWith(ramadan: week)
      : copyWith(regular: week);

  bool get isComplete =>
      !own || ((regular?.isComplete ?? false) && (ramadan?.isComplete ?? true));

  @override
  bool operator ==(Object other) =>
      other is HoursDraft &&
      other.own == own &&
      other.regular == regular &&
      other.ramadan == ramadan;

  @override
  int get hashCode => Object.hash(own, regular, ramadan);
}

@immutable
class StatusDraft {
  final bool own;

  final String? status;

  final String? reopensOn;

  const StatusDraft({required this.own, this.status, this.reopensOn});

  @override
  bool operator ==(Object other) =>
      other is StatusDraft &&
      other.own == own &&
      other.status == status &&
      other.reopensOn == reopensOn;

  @override
  int get hashCode => Object.hash(own, status, reopensOn);
}

@immutable
class ScopeDraft {
  final String? locationId;
  final HoursDraft hours;
  final StatusDraft status;

  const ScopeDraft({
    required this.locationId,
    required this.hours,
    required this.status,
  });

  bool get isVenue => locationId == null;

  factory ScopeDraft.fromServer(EditableScopeHoursDto scope) {
    final isVenue = scope.locationId == null;
    final ownHours = isVenue || scope.ownsHours;
    final ownStatus = isVenue || scope.ownsStatus;
    final regular = scope.regular;
    final ramadan = scope.ramadan;
    return ScopeDraft(
      locationId: scope.locationId,
      hours: HoursDraft(
        own: ownHours,
        regular: !ownHours
            ? null
            : regular != null
            ? DraftWeek.fromDto(regular)
            : DraftWeek.starting(),
        ramadan: ownHours && ramadan != null
            ? DraftWeek.fromDto(ramadan)
            : null,
      ),
      status: StatusDraft(
        own: ownStatus,
        status: ownStatus
            ? (scope.operatingStatus ?? VenueOperatingStatus.open)
            : null,
        reopensOn: ownStatus ? scope.reopensOn : null,
      ),
    );
  }

  ScopeDraft copyWith({HoursDraft? hours, StatusDraft? status}) => ScopeDraft(
    locationId: locationId,
    hours: hours ?? this.hours,
    status: status ?? this.status,
  );

  @override
  bool operator ==(Object other) =>
      other is ScopeDraft &&
      other.locationId == locationId &&
      other.hours == hours &&
      other.status == status;

  @override
  int get hashCode => Object.hash(locationId, hours, status);
}
