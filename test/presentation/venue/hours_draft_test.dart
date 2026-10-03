import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/hours_draft.dart';
import 'package:hangout/presentation/venue/utils/hours_editor_validation.dart';

import '../../helpers/hours_test_helpers.dart';

const _range = DraftInterval(opens: '16:00', closes: '23:00');

DraftDay _hours(int dow, List<DraftInterval> intervals) =>
    DraftDay(dayOfWeek: dow, kind: HoursDayKind.hours, intervals: intervals);

DraftInterval _iv(String opens, String closes) =>
    DraftInterval(opens: opens, closes: closes);

ApplyRangeConflict _hits(int dow, [String? opens, String? closes]) =>
    ApplyRangeConflict.overlap(
      HoursSegmentRef(dow, opens: opens, closes: closes),
    );

DraftWeek _week([List<DraftDay> days = const []]) {
  var w = DraftWeek.fromDto(week([iv('09:00', '13:00')]));
  for (final d in days) {
    w = w.withDay(d);
  }
  return w;
}

void main() {
  test('incompleteDays lists the HOURS days with a time to pick', () {
    final w = DraftWeek.starting()
        .withDay(
          const DraftDay(
            dayOfWeek: 6,
            kind: HoursDayKind.hours,
            intervals: [DraftInterval(opens: '09:00', closes: '17:00')],
          ),
        )
        .withDay(const DraftDay(dayOfWeek: 5, kind: HoursDayKind.closed))
        .withDay(
          const DraftDay(
            dayOfWeek: 0,
            kind: HoursDayKind.hours,
            intervals: [
              DraftInterval(opens: '09:00', closes: '13:00'),
              DraftInterval(opens: '16:00'),
            ],
          ),
        );
    expect(w.incompleteDays, {0, 1, 2, 3, 4});
    expect(
      DraftWeek.fromDto(week([iv('09:00', '02:00')])).incompleteDays,
      isEmpty,
    );
  });

  group('applyToDays: replace', () {
    test('HOURS, CLOSED and 24 h days all become HOURS with the one range', () {
      final w = _week([
        _hours(0, [_iv('08:00', '12:00'), _iv('14:00', '18:00')]),
        const DraftDay(
          dayOfWeek: 1,
          kind: HoursDayKind.closed,
          intervals: [DraftInterval(opens: '10:00', closes: '11:00')],
        ),
        const DraftDay(dayOfWeek: 2, kind: HoursDayKind.open24h),
      ]);
      final next = w.applyToDays(_range, {0, 1, 2}, ApplyRangeMode.replace);
      for (final dow in [0, 1, 2]) {
        expect(next.day(dow).kind, HoursDayKind.hours, reason: '$dow');
        expect(next.day(dow).intervals, [_range], reason: '$dow');
      }
    });

    test('the days not chosen are untouched — the very same objects', () {
      final w = _week([
        const DraftDay(dayOfWeek: 5, kind: HoursDayKind.closed),
        _hours(3, [const DraftInterval(opens: '09:00')]),
      ]);
      final next = w.applyToDays(_range, {6, 0}, ApplyRangeMode.replace);
      for (final dow in [1, 2, 3, 4, 5]) {
        expect(identical(next.day(dow), w.day(dow)), isTrue, reason: '$dow');
      }
      expect(w.day(6).intervals, [_iv('09:00', '13:00')]);
    });

    test('all seven days never conflict, even overnight', () {
      final w = _week([
        const DraftDay(dayOfWeek: 2, kind: HoursDayKind.open24h),
      ]);
      const overnight = DraftInterval(opens: '18:00', closes: '04:00');
      const all = {0, 1, 2, 3, 4, 5, 6};
      expect(w.applyConflicts(overnight, all, ApplyRangeMode.replace), isEmpty);
      final next = w.applyToDays(overnight, all, ApplyRangeMode.replace);
      expect(validateWeeklySchedule(next.toInput().days), isNull);
    });
  });

  group('applyToDays: add', () {
    test('adds to an HOURS day, keeping its ranges in opening order', () {
      final next = _week().applyToDays(_range, {4}, ApplyRangeMode.add);
      expect(next.day(4).intervals, [_iv('09:00', '13:00'), _range]);
      final early = _week().applyToDays(_iv('06:00', '08:00'), {
        4,
      }, ApplyRangeMode.add);
      expect(early.day(4).intervals, [
        _iv('06:00', '08:00'),
        _iv('09:00', '13:00'),
      ]);
    });

    test('drops a range still being picked before appending', () {
      final w = DraftWeek.starting().withDay(
        _hours(1, [_iv('09:00', '12:00'), const DraftInterval(opens: '13:00')]),
      );
      final next = w.applyToDays(_range, {0, 1}, ApplyRangeMode.add);
      expect(next.day(0).intervals, [_range]);
      expect(next.day(1).intervals, [_iv('09:00', '12:00'), _range]);
      expect(next.day(1).isComplete, isTrue);
    });

    test('a CLOSED or 24 h day becomes HOURS with just this range', () {
      final w = _week([
        const DraftDay(
          dayOfWeek: 5,
          kind: HoursDayKind.closed,
          intervals: [DraftInterval(opens: '10:00', closes: '11:00')],
        ),
        const DraftDay(dayOfWeek: 6, kind: HoursDayKind.open24h),
      ]);
      final next = w.applyToDays(_range, {5, 6}, ApplyRangeMode.add);
      expect(next.day(5), _hours(5, [_range]));
      expect(next.day(5).intervals, [_range]);
      expect(next.day(6), _hours(6, [_range]));
    });
  });

  group('applyConflicts', () {
    test('an overnight range occupies the next morning (Sun 18–02 vs Mon '
        '01–03)', () {
      final w = _week([
        _hours(0, [_iv('18:00', '02:00')]),
        _hours(1, [_iv('09:00', '13:00')]),
      ]);
      const early = DraftInterval(opens: '01:00', closes: '03:00');
      expect(w.applyConflicts(early, {1}, ApplyRangeMode.add), {
        1: _hits(0, '18:00', '02:00'),
      });
      expect(w.applyConflicts(early, {1}, ApplyRangeMode.replace), {
        1: _hits(0, '18:00', '02:00'),
      });
      expect(
        w.applyConflicts(_iv('02:00', '05:00'), {1}, ApplyRangeMode.add),
        isEmpty,
      );
    });

    test('a new overnight range runs into the next day\'s morning', () {
      final w = _week([
        _hours(3, [_iv('01:00', '05:00'), _iv('09:00', '13:00')]),
      ]);
      const late = DraftInterval(opens: '22:00', closes: '03:00');
      expect(w.applyConflicts(late, {2}, ApplyRangeMode.add), {
        2: _hits(3, '01:00', '05:00'),
      });
      expect(w.applyConflicts(late, {2, 3}, ApplyRangeMode.replace), isEmpty);
    });

    test('Saturday night runs into Sunday', () {
      final w = _week([
        _hours(0, [_iv('02:00', '06:00')]),
      ]);
      expect(w.applyConflicts(_iv('20:00', '03:00'), {6}, ApplyRangeMode.add), {
        6: _hits(0, '02:00', '06:00'),
      });
      expect(
        w.applyConflicts(_iv('20:00', '02:00'), {6}, ApplyRangeMode.add),
        isEmpty,
      );
    });

    test('a 24 h neighbour counts whole', () {
      final w = _week([
        const DraftDay(dayOfWeek: 1, kind: HoursDayKind.open24h),
      ]);
      expect(w.applyConflicts(_iv('20:00', '00:30'), {0}, ApplyRangeMode.add), {
        0: _hits(1),
      });
      expect(
        w.applyConflicts(_iv('20:00', '00:00'), {0}, ApplyRangeMode.add),
        isEmpty,
      );
    });

    test('the same day: an overlapping range, or the very same one', () {
      final w = _week();
      expect(
        w.applyConflicts(_iv('12:00', '15:00'), {0, 1}, ApplyRangeMode.add),
        {0: _hits(0, '09:00', '13:00'), 1: _hits(1, '09:00', '13:00')},
      );
      expect(w.applyConflicts(_iv('09:00', '13:00'), {4}, ApplyRangeMode.add), {
        4: _hits(4, '09:00', '13:00'),
      });
      expect(
        w.applyConflicts(_iv('12:00', '15:00'), {0, 1}, ApplyRangeMode.replace),
        isEmpty,
      );
    });

    test('a fifth range is refused; a placeholder doesn\'t count', () {
      final four = [
        _iv('06:00', '07:00'),
        _iv('08:00', '09:00'),
        _iv('10:00', '11:00'),
        _iv('12:00', '13:00'),
      ];
      final w = _week([
        _hours(4, four),
        _hours(5, [...four.take(3), const DraftInterval(opens: '14:00')]),
      ]);
      expect(w.applyConflicts(_range, {4, 5}, ApplyRangeMode.add), {
        4: const ApplyRangeConflict.tooMany(),
      });
      expect(w.applyToDays(_range, {5}, ApplyRangeMode.add).day(5).intervals, [
        ...four.take(3),
        _range,
      ]);
      expect(w.applyConflicts(_range, {4}, ApplyRangeMode.replace), isEmpty);
    });

    test('names the same day first, then the day before, then the next', () {
      final w = _week([
        _hours(0, [_iv('22:00', '02:00')]),
        _hours(1, [_iv('03:00', '05:00')]),
        _hours(2, [_iv('00:00', '01:00'), _iv('09:00', '13:00')]),
      ]);
      expect(w.applyConflicts(_iv('01:00', '04:00'), {1}, ApplyRangeMode.add), {
        1: _hits(1, '03:00', '05:00'),
      });
      expect(
        w.applyConflicts(_iv('01:00', '00:30'), {1}, ApplyRangeMode.replace),
        {1: _hits(0, '22:00', '02:00')},
      );
      expect(
        w.applyConflicts(_iv('02:00', '00:30'), {1}, ApplyRangeMode.replace),
        {1: _hits(2, '00:00', '01:00')},
      );
    });

    test('an invalid kept range still counts towards the 4', () {
      final w = _week([
        _hours(4, [
          _iv('06:00', '07:00'),
          _iv('08:00', '09:00'),
          _iv('10:00', '10:00'),
          _iv('12:00', '13:00'),
        ]),
      ]);
      expect(w.applyConflicts(_range, {4}, ApplyRangeMode.add), {
        4: const ApplyRangeConflict.tooMany(),
      });
    });

    test('only chosen days are reported, and a clean apply saves', () {
      final w = _week([
        _hours(0, [_iv('18:00', '02:00')]),
      ]);
      const early = DraftInterval(opens: '01:00', closes: '03:00');
      final conflicts = w.applyConflicts(early, {1, 2, 3}, ApplyRangeMode.add);
      expect(conflicts.keys, [1]);
      final next = w.applyToDays(early, {2, 3}, ApplyRangeMode.add);
      expect(validateWeeklySchedule(next.toInput().days), isNull);
    });
  });

  group('HoursDraft seasons', () {
    test('withWeek changes one season and leaves the other', () {
      final regular = _week();
      final ramadan = DraftWeek.fromDto(week([iv('20:00', '03:00')]));
      final draft = HoursDraft(own: true, regular: regular, ramadan: ramadan);
      final next = regular.applyToDays(_range, {0}, ApplyRangeMode.replace);

      final r = draft.withWeek(HoursSeason.regular, next);
      expect(r.week(HoursSeason.regular), next);
      expect(identical(r.week(HoursSeason.ramadan), ramadan), isTrue);

      final m = draft.withWeek(HoursSeason.ramadan, next);
      expect(m.week(HoursSeason.ramadan), next);
      expect(identical(m.week(HoursSeason.regular), regular), isTrue);
    });
  });

  group('rangeErrorCode', () {
    test('the per-range rules the save enforces', () {
      expect(rangeErrorCode('09:00', '17:00'), isNull);
      expect(rangeErrorCode('18:00', '02:00'), isNull);
      expect(rangeErrorCode('18:00', '00:00'), isNull);
      expect(rangeErrorCode('00:00', '00:00'), 'HOURS_EMPTY_INTERVAL');
      expect(rangeErrorCode('10:00', '10:00'), 'HOURS_EMPTY_INTERVAL');
      expect(rangeErrorCode('10:00', '10:10'), 'HOURS_INTERVAL_TOO_SHORT');
      expect(rangeErrorCode('23:55', '00:05'), 'HOURS_INTERVAL_TOO_SHORT');
      expect(rangeErrorCode('9:00', '17:00'), 'HOURS_INVALID_TIME');
    });
  });
}
