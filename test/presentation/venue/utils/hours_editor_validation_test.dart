import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/domain/dto/request/venue_hours_requests.dart';
import 'package:hangout/presentation/venue/utils/hours_editor_validation.dart';

HoursIntervalInput _i(String opens, String closes) =>
    HoursIntervalInput(opens: opens, closes: closes);

HoursDayInput _hours(int dow, List<HoursIntervalInput> intervals) =>
    HoursDayInput(dayOfWeek: dow, kind: 'HOURS', intervals: intervals);

HoursDayInput _allDay(int dow) =>
    HoursDayInput(dayOfWeek: dow, kind: 'OPEN_24H');

List<HoursDayInput> _week(Map<int, HoursDayInput> days) => [
  for (var d = 0; d < 7; d++)
    days[d] ?? HoursDayInput(dayOfWeek: d, kind: 'CLOSED'),
];

String? _code(List<HoursDayInput> days) => validateWeeklySchedule(days)?.code;

const _sun = 0, _mon = 1, _tue = 2, _thu = 4, _fri = 5, _sat = 6;

void main() {
  group('validateWeeklySchedule (V1–V21)', () {
    test('V1 six days', () {
      expect(_code(_week({})..removeLast()), 'HOURS_DAYS_INCOMPLETE');
    });

    test('V2 a dayOfWeek twice', () {
      final days = _week({})
        ..[2] = const HoursDayInput(dayOfWeek: 3, kind: 'CLOSED');
      expect(_code(days), 'HOURS_DAYS_INCOMPLETE');
    });

    test('V3 09:00–09:00', () {
      expect(
        _code(
          _week({
            _mon: _hours(_mon, [_i('09:00', '09:00')]),
          }),
        ),
        'HOURS_EMPTY_INTERVAL',
      );
    });

    test('V4 overlapping intervals on one day', () {
      expect(
        _code(
          _week({
            _mon: _hours(_mon, [_i('09:00', '13:00'), _i('12:00', '18:00')]),
          }),
        ),
        'HOURS_OVERLAP',
      );
    });

    test('V5 touching intervals are valid', () {
      expect(
        _code(
          _week({
            _mon: _hours(_mon, [_i('09:00', '13:00'), _i('13:00', '18:00')]),
          }),
        ),
        isNull,
      );
    });

    test('V6 an overnight tail into the next day', () {
      final error = validateWeeklySchedule(
        _week({
          _thu: _hours(_thu, [_i('18:00', '03:00')]),
          _fri: _hours(_fri, [_i('02:00', '10:00')]),
        }),
      );
      expect(error?.code, 'HOURS_OVERLAP');
      expect(error?.detail, 'Thu 18:00–03:00 overlaps Fri 02:00–10:00');
      expect(error?.conflict.map((r) => r.dayOfWeek), [_thu, _fri]);
    });

    test('V7 the Saturday night wraps into Sunday', () {
      expect(
        _code(
          _week({
            _sat: _hours(_sat, [_i('22:00', '02:00')]),
            _sun: _hours(_sun, [_i('01:00', '05:00')]),
          }),
        ),
        'HOURS_OVERLAP',
      );
    });

    test('V8 five intervals', () {
      expect(
        _code(
          _week({
            _mon: _hours(_mon, [
              _i('01:00', '02:00'),
              _i('03:00', '04:00'),
              _i('05:00', '06:00'),
              _i('07:00', '08:00'),
              _i('09:00', '10:00'),
            ]),
          }),
        ),
        'HOURS_TOO_MANY_INTERVALS',
      );
    });

    test('V9 CLOSED with an interval', () {
      expect(
        _code(
          _week({
            _mon: HoursDayInput(
              dayOfWeek: _mon,
              kind: 'CLOSED',
              intervals: [_i('09:00', '10:00')],
            ),
          }),
        ),
        'HOURS_KIND_MISMATCH',
      );
    });

    test('V10 HOURS without intervals', () {
      expect(_code(_week({_mon: _hours(_mon, [])})), 'HOURS_KIND_MISMATCH');
    });

    for (final (opens, closes) in [
      ('09:00', '24:00'),
      ('9:00', '17:00'),
      ('09:00:00', '17:00'),
    ]) {
      test('V11 "$opens"–"$closes" is not HH:mm', () {
        expect(
          _code(
            _week({
              _mon: _hours(_mon, [_i(opens, closes)]),
            }),
          ),
          'HOURS_INVALID_TIME',
        );
      });
    }

    test('V12 ten minutes', () {
      expect(
        _code(
          _week({
            _mon: _hours(_mon, [_i('10:00', '10:10')]),
          }),
        ),
        'HOURS_INTERVAL_TOO_SHORT',
      );
    });

    test('V13 an overnight tail into a 24 h day', () {
      expect(
        _code(
          _week({
            _thu: _hours(_thu, [_i('18:00', '03:00')]),
            _fri: _allDay(_fri),
          }),
        ),
        'HOURS_OVERLAP',
      );
    });

    test('V14 two overnight intervals overlap', () {
      expect(
        _code(
          _week({
            _mon: _hours(_mon, [_i('20:00', '02:00'), _i('21:00', '01:00')]),
          }),
        ),
        'HOURS_OVERLAP',
      );
    });

    test('V15 a 23 h overnight alone is valid', () {
      expect(
        _code(
          _week({
            _mon: _hours(_mon, [_i('23:00', '22:00')]),
          }),
        ),
        isNull,
      );
    });

    test('V16 …–00:00 touching a 24 h day is valid', () {
      expect(
        _code(
          _week({
            _mon: _hours(_mon, [_i('18:00', '00:00')]),
            _tue: _allDay(_tue),
          }),
        ),
        isNull,
      );
    });

    test('V17 two 24 h days', () {
      expect(_code(_week({_mon: _allDay(_mon), _tue: _allDay(_tue)})), isNull);
    });

    test('V18 Sat 24 h touching Sun 00:00 across the wrap', () {
      expect(
        _code(
          _week({
            _sat: _allDay(_sat),
            _sun: _hours(_sun, [_i('00:00', '02:00')]),
          }),
        ),
        isNull,
      );
    });

    test('V19 Sat …–00:00 then Sun 00:00–…', () {
      expect(
        _code(
          _week({
            _sat: _hours(_sat, [_i('18:00', '00:00')]),
            _sun: _hours(_sun, [_i('00:00', '02:00')]),
          }),
        ),
        isNull,
      );
    });

    test('V20 a morning and an overnight range (Tue closed)', () {
      expect(
        _code(
          _week({
            _mon: _hours(_mon, [_i('08:00', '12:00'), _i('23:00', '07:00')]),
          }),
        ),
        isNull,
      );
    });

    test('V21 unknown kind', () {
      expect(
        _code(
          _week({
            _mon: const HoursDayInput(dayOfWeek: _mon, kind: 'SOMETIMES'),
          }),
        ),
        'HOURS_INVALID_KIND',
      );
    });

    test('client only: a time not picked yet (empty string)', () {
      final error = validateWeeklySchedule(
        _week({
          _mon: _hours(_mon, [_i('09:00', '')]),
        }),
      );
      expect(error?.code, 'HOURS_INTERVAL_INCOMPLETE');
      expect(error?.dayOfWeek, _mon);
    });
  });

  group('request-level rules (V22–V28)', () {
    const today = '2026-09-28';

    test('V22 reopensOn with OPEN', () {
      expect(
        validateOperatingStatus('OPEN', '2026-10-01', today)?.code,
        'STATUS_REOPEN_DATE_NOT_ALLOWED',
      );
    });

    test(
      'V23 reopensOn today or today + 366 is invalid; +1 and +365 are fine',
      () {
        String? code(String d) =>
            validateOperatingStatus('TEMPORARILY_CLOSED', d, today)?.code;
        expect(code('2026-09-28'), 'STATUS_REOPEN_DATE_INVALID');
        expect(code('2027-09-29'), 'STATUS_REOPEN_DATE_INVALID');
        expect(code('2026-09-29'), isNull);
        expect(code('2027-09-28'), isNull);
        expect(code('2026-02-30'), 'STATUS_REOPEN_DATE_INVALID');
      },
    );

    test('V24 branch INHERIT with a schedule', () {
      expect(
        checkBranchScheduleRequest(
          mode: 'INHERIT',
          hasRegular: true,
          hasRamadan: false,
          removeRamadan: false,
        )?.code,
        'HOURS_INHERIT_WITH_SCHEDULE',
      );
    });

    test('V25 branch OWN without regular', () {
      expect(
        checkBranchScheduleRequest(
          mode: 'OWN',
          hasRegular: false,
          hasRamadan: false,
          removeRamadan: false,
        )?.code,
        'HOURS_REGULAR_REQUIRED',
      );
    });

    test('V26 branch status INHERIT with a status', () {
      expect(
        validateBranchOperatingStatus('INHERIT', 'OPEN', null, today)?.code,
        'STATUS_INHERIT_WITH_VALUE',
      );
    });

    test('V27 branch status OWN without a status', () {
      expect(
        validateBranchOperatingStatus('OWN', null, null, today)?.code,
        'STATUS_REQUIRED',
      );
    });

    test('V28 ramadan and removeRamadan together', () {
      expect(
        checkScheduleRequest(
          hasRegular: true,
          hasRamadan: true,
          removeRamadan: true,
        )?.code,
        'HOURS_RAMADAN_CONFLICT',
      );
    });
  });
}
