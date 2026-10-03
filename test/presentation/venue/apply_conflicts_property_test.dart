import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/domain/dto/request/venue_hours_requests.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/hours_draft.dart';
import 'package:hangout/presentation/venue/utils/hours_editor_validation.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';

String _hm(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

int _quarter(Random rnd) => rnd.nextInt(96) * 15;

DraftWeek _randomWeek(Random rnd) {
  var w = DraftWeek.starting();
  for (var dow = 0; dow < 7; dow++) {
    final roll = rnd.nextInt(10);
    if (roll == 0) {
      w = w.withDay(DraftDay(dayOfWeek: dow, kind: HoursDayKind.closed));
      continue;
    }
    if (roll == 1) {
      w = w.withDay(DraftDay(dayOfWeek: dow, kind: HoursDayKind.open24h));
      continue;
    }
    final n = 1 + rnd.nextInt(4);
    final points = <int>{};
    while (points.length < 2 * n) {
      points.add(_quarter(rnd));
    }
    final sorted = points.toList()..sort();
    final intervals = [
      for (var i = 0; i < n; i++)
        DraftInterval(
          opens: _hm(sorted[2 * i]),
          closes: _hm(sorted[2 * i + 1]),
        ),
    ];
    if (rnd.nextInt(3) == 0) {
      final last = intervals.removeLast();
      intervals.add(
        DraftInterval(opens: last.opens, closes: _hm(rnd.nextInt(8) * 60)),
      );
    }
    if (rnd.nextInt(4) == 0) intervals.shuffle(rnd);
    if (intervals.length < kMaxIntervalsPerDay && rnd.nextInt(6) == 0) {
      intervals.add(DraftInterval(opens: _hm(_quarter(rnd))));
    }
    w = w.withDay(
      DraftDay(dayOfWeek: dow, kind: HoursDayKind.hours, intervals: intervals),
    );
  }
  return w;
}

HoursValidationError? _verdict(DraftWeek w) => validateWeeklySchedule([
  for (final day in w.days)
    () {
      final picked = day.effectiveIntervals.where((i) => i.isComplete);
      final kind = day.kind == HoursDayKind.hours && picked.isEmpty
          ? HoursDayKind.closed
          : day.kind;
      return HoursDayInput(
        dayOfWeek: day.dayOfWeek,
        kind: kind.wire,
        intervals: [
          for (final i in picked)
            HoursIntervalInput(opens: i.opens!, closes: i.closes!),
        ],
      );
    }(),
]);

DraftWeek _pair(DraftInterval range, int dow, HoursSegmentRef other) {
  var w = DraftWeek.starting();
  for (var d = 0; d < 7; d++) {
    w = w.withDay(DraftDay(dayOfWeek: d, kind: HoursDayKind.closed));
  }
  final otherRange = other.isAllDay
      ? null
      : DraftInterval(opens: other.opens, closes: other.closes);
  if (otherRange == null) {
    w = w.withDay(
      DraftDay(dayOfWeek: other.dayOfWeek, kind: HoursDayKind.open24h),
    );
  } else if (other.dayOfWeek != dow) {
    w = w.withDay(
      DraftDay(
        dayOfWeek: other.dayOfWeek,
        kind: HoursDayKind.hours,
        intervals: [otherRange],
      ),
    );
  }
  return w.withDay(
    DraftDay(
      dayOfWeek: dow,
      kind: HoursDayKind.hours,
      intervals: [range, if (other.dayOfWeek == dow) otherRange!],
    ),
  );
}

void main() {
  test('applyConflicts agrees with the save\'s validator', () {
    final rnd = Random(20260929);
    var checked = 0, clean = 0, flagged = 0, neighbour = 0, tooMany = 0;
    for (var iteration = 0; iteration < 6000; iteration++) {
      final week = _randomWeek(rnd);
      if (_verdict(week) != null) continue;
      final opens = _quarter(rnd);
      final closes = _quarter(rnd);
      if (rangeErrorCode(_hm(opens), _hm(closes)) != null) continue;
      final range = DraftInterval(opens: _hm(opens), closes: _hm(closes));
      final days = {
        for (var dow = 0; dow < 7; dow++)
          if (rnd.nextBool()) dow,
      };
      if (days.isEmpty) continue;
      final mode = rnd.nextBool() ? ApplyRangeMode.add : ApplyRangeMode.replace;
      final what = '$mode ${range.opens}–${range.closes} on $days';
      checked++;

      final conflicts = week.applyConflicts(range, days, mode);
      final result = week.applyToDays(range, days, mode);
      final verdict = _verdict(result);
      expect(conflicts.keys.toSet().difference(days), isEmpty, reason: what);
      for (final dow in days) {
        final starts = [for (final i in result.day(dow).intervals) i.opens!];
        expect(starts, [...starts]..sort(), reason: '$what: in order');
      }
      if (conflicts.isEmpty) {
        clean++;
        expect(verdict, isNull, reason: '$what: clean, but $verdict');
        continue;
      }
      flagged++;
      expect(
        verdict?.code,
        isIn([
          VenueErrorCodes.hoursOverlap,
          VenueErrorCodes.hoursTooManyIntervals,
        ]),
        reason: '$what: flagged $conflicts, but the save says $verdict',
      );

      for (final MapEntry(key: dow, value: conflict) in conflicts.entries) {
        final why = '$what: $dow $conflict';
        expect(
          week.applyConflicts(range, {dow}, mode).containsKey(dow),
          isTrue,
          reason: '$why is not a conflict on its own',
        );
        if (conflict.kind == ApplyConflictKind.tooMany) {
          tooMany++;
          expect(
            result.day(dow).intervals.length,
            greaterThan(kMaxIntervalsPerDay),
            reason: why,
          );
          continue;
        }
        final other = conflict.other!;
        if (other.dayOfWeek != dow) neighbour++;
        expect(
          _verdict(_pair(range, dow, other))?.code,
          VenueErrorCodes.hoursOverlap,
          reason: '$why: the range named doesn\'t collide',
        );
      }
    }
    expect(checked, greaterThan(1000));
    expect(clean, greaterThan(100));
    expect(flagged, greaterThan(100));
    expect(neighbour, greaterThan(50));
    expect(tooMany, greaterThan(10));
  });
}
