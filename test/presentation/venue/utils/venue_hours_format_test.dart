import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';

import '../../../helpers/locale_test_helper.dart';

HoursMomentDto _m(String time, int dayOffset, {int dow = 2}) => HoursMomentDto(
  at: '2026-09-29T$time:00+03:00',
  localTime: time,
  localDate: '2026-09-29',
  dayOfWeek: dow,
  dayOffset: dayOffset,
);

OpenStatusDto _open(
  String time,
  int offset, {
  int dow = 2,
  bool soon = false,
}) => OpenStatusDto(
  state: OpenState.open,
  openNow: true,
  closingSoon: soon,
  closesAt: _m(time, offset, dow: dow),
);

OpenStatusDto _closed(
  String time,
  int offset, {
  int dow = 2,
  bool soon = false,
}) => OpenStatusDto(
  state: OpenState.closed,
  openNow: false,
  openingSoon: soon,
  opensAt: _m(time, offset, dow: dow),
);

const _iso = '\u2068';
const _pdi = '\u2069';

void main() {
  group('Arabic', () {
    setUpAll(() => loadTestLocale('ar'));

    group('statusLabel — the spec §6.6 expected-label table', () {
      final cases = <String, (OpenStatusDto, String)>{
        'A1 OPEN, closes 17:00 (+0)': (
          _open('17:00', 0),
          'مفتوح الآن · يغلق 5:00 م',
        ),
        'A2 closingSoon, 17:00 (+0)': (
          _open('17:00', 0, soon: true),
          'يغلق قريباً · 5:00 م',
        ),
        'A9 OPEN, closes 00:00 (+2)': (
          _open('00:00', 2, dow: 3),
          'مفتوح الآن · يغلق غداً منتصف الليل',
        ),
        'A10 / B2 OPEN, closes 00:00 (+1)': (
          _open('00:00', 1),
          'مفتوح الآن · يغلق منتصف الليل',
        ),
        'A11 / B3 closingSoon, 00:00 (+1)': (
          _open('00:00', 1, soon: true),
          'يغلق قريباً · منتصف الليل',
        ),
        'H2 OPEN, closes 03:00 (+1) — no «غداً» before 06:00': (
          _open('03:00', 1),
          'مفتوح الآن · يغلق 3:00 ص',
        ),
        'A13 closingSoon, 03:00 (+0)': (
          _open('03:00', 0, soon: true),
          'يغلق قريباً · 3:00 ص',
        ),
        'A4 CLOSED, opens 08:00 (+1)': (
          _closed('08:00', 1),
          'مغلق الآن · يفتح غداً 8:00 ص',
        ),
        'A6 openingSoon, 09:00 (+0)': (
          _closed('09:00', 0, soon: true),
          'يفتح قريباً · 9:00 ص',
        ),
        'E2 CLOSED, opens Sat 22:00 (+6)': (
          _closed('22:00', 6, dow: 6),
          'مغلق الآن · يفتح السبت 10:00 م',
        ),
        'F1 CLOSED, opens Fri 16:00 (+7)': (
          _closed('16:00', 7, dow: 5),
          'مغلق الآن · يفتح الجمعة من الأسبوع القادم 4:00 م',
        ),
        'synthetic OPEN, closes Tue 00:00 (+3)': (
          _open('00:00', 3, dow: 2),
          'مفتوح الآن · يغلق الاثنين منتصف الليل',
        ),
        'synthetic OPEN, closes 08:00 (+1)': (
          _open('08:00', 1),
          'مفتوح الآن · يغلق غداً 8:00 ص',
        ),
        'B1 alwaysOpen': (
          const OpenStatusDto(
            state: OpenState.open,
            openNow: true,
            alwaysOpen: true,
          ),
          'مفتوح 24 ساعة',
        ),
        'G2 TEMP, reopensOn 10-06': (
          const OpenStatusDto(
            state: OpenState.temporarilyClosed,
            openNow: false,
            reopensOn: '2026-10-06',
          ),
          'مغلق مؤقتاً · يعود للعمل 6 أكتوبر',
        ),
        'G6 PERM': (
          const OpenStatusDto(
            state: OpenState.permanentlyClosed,
            openNow: false,
          ),
          'مغلق نهائياً',
        ),
      };
      cases.forEach((name, c) {
        test(name, () => expect(statusLabel(c.$1, 'ar'), c.$2));
      });

      test('other cases', () {
        expect(
          statusLabel(
            const OpenStatusDto(state: OpenState.temporarilyClosed),
            'ar',
          ),
          'مغلق مؤقتاً',
        );
        expect(
          statusLabel(
            const OpenStatusDto(state: OpenState.closed, openNow: false),
            'ar',
          ),
          'مغلق الآن',
        );
        expect(
          statusLabel(_closed('16:00', 3, dow: 4), 'ar'),
          'مغلق الآن · يفتح الخميس 4:00 م',
        );
        expect(
          statusLabel(_closed('18:00', 0), 'ar'),
          'مغلق الآن · يفتح 6:00 م',
        );
        expect(
          statusLabel(_open('10:00', 2, dow: 3), 'ar'),
          'مفتوح الآن · يغلق الأربعاء 10:00 ص',
        );
        expect(statusLabel(const OpenStatusDto(), 'ar'), '');
      });
    });

    test('weekdayName follows the wire day (0 = Sunday)', () {
      expect(
        [for (var d = 0; d < 7; d++) weekdayName(d, 'ar')],
        [
          'الأحد',
          'الاثنين',
          'الثلاثاء',
          'الأربعاء',
          'الخميس',
          'الجمعة',
          'السبت',
        ],
      );
    });

    test('formatHm uses the app-wide h:mm a', () {
      expect(formatHm('09:00', 'ar'), '9:00 ص');
      expect(formatHm('17:30', 'ar'), '5:30 م');
      expect(formatHm('00:15', 'ar'), '12:15 ص');
      expect(formatHm('bogus', 'ar'), 'bogus');
    });

    test('formatInterval: overnight tail, midnight close, isolates', () {
      expect(
        formatInterval(
          const HoursIntervalDto(
            opens: '09:00',
            closes: '02:00',
            overnight: true,
          ),
          'ar',
        ),
        '${_iso}9:00 ص$_pdi – ${_iso}2:00 ص$_pdi (اليوم التالي)',
      );
      expect(
        formatInterval(
          const HoursIntervalDto(
            opens: '18:00',
            closes: '00:00',
            overnight: true,
          ),
          'ar',
        ),
        '${_iso}6:00 م$_pdi – $_iso'
        'منتصف الليل$_pdi',
      );
      expect(
        formatInterval(
          const HoursIntervalDto(opens: '09:00', closes: '13:00'),
          'ar',
        ),
        '${_iso}9:00 ص$_pdi – ${_iso}1:00 م$_pdi',
      );
    });

    test('formatDayRule', () {
      expect(formatDayRule(HoursDayKind.closed, const [], 'ar'), 'مغلق');
      expect(
        formatDayRule(HoursDayKind.open24h, const [], 'ar'),
        'مفتوح 24 ساعة',
      );
      expect(
        formatDayRule(HoursDayKind.hours, const [
          HoursIntervalDto(opens: '09:00', closes: '13:00'),
          HoursIntervalDto(opens: '16:00', closes: '02:00', overnight: true),
        ], 'ar'),
        '${_iso}9:00 ص$_pdi – ${_iso}1:00 م$_pdi، '
        '${_iso}4:00 م$_pdi – ${_iso}2:00 ص$_pdi (اليوم التالي)',
      );
    });

    test('dates: d MMM, Baghdad date of an instant, freshness line', () {
      expect(formatHoursDate('2026-10-06', 'ar'), '6 أكتوبر');
      expect(baghdadDateOf('2026-09-20T22:30:00Z'), '2026-09-21');
      expect(baghdadDateOf('2026-09-20T10:12:44Z'), '2026-09-20');
      expect(
        updatedOnLabel('2026-09-20T10:12:44Z', 'ar'),
        'آخر تحديث 20 سبتمبر',
      );
      expect(
        ramadanWindowLabel(
          const RamadanWindowDto(startsOn: '2027-02-08', endsOn: '2027-03-09'),
          'ar',
        ),
        'رمضان: 8 فبراير – 9 مارس',
      );
    });
  });

  group('English', () {
    setUpAll(() => loadTestLocale('en'));

    test('statusLabel', () {
      expect(statusLabel(_open('03:00', 1), 'en'), 'Open now · Closes 3:00 AM');
      expect(
        statusLabel(_open('00:00', 2, dow: 3), 'en'),
        'Open now · Closes tomorrow at midnight',
      );
      expect(
        statusLabel(_closed('16:00', 7, dow: 5), 'en'),
        'Closed now · Opens next Friday 4:00 PM',
      );
      expect(
        statusLabel(_open('00:00', 1, soon: true), 'en'),
        'Closes soon · Midnight',
      );
    });

    test('weekdayName / formatDayRule separator', () {
      expect(weekdayName(6, 'en'), 'Saturday');
      expect(
        formatDayRule(HoursDayKind.hours, const [
          HoursIntervalDto(opens: '09:00', closes: '13:00'),
          HoursIntervalDto(opens: '16:00', closes: '18:00'),
        ], 'en'),
        '${_iso}9:00 AM$_pdi – ${_iso}1:00 PM$_pdi, ${_iso}4:00 PM$_pdi – ${_iso}6:00 PM$_pdi',
      );
    });
  });

  group('locale-free helpers', () {
    setUpAll(() => loadTestLocale('ar'));

    test('kIraqWeekOrder is Saturday first on the 0 = Sunday wire', () {
      expect(kIraqWeekOrder, [6, 0, 1, 2, 3, 4, 5]);
    });

    test('daysInIraqOrder fills a missing day as CLOSED', () {
      final days = daysInIraqOrder(
        const WeeklyScheduleDto(
          days: [
            DayScheduleDto(dayOfWeek: 0, kind: HoursDayKind.open24h),
            DayScheduleDto(
              dayOfWeek: 6,
              kind: HoursDayKind.hours,
              intervals: [
                HoursIntervalDto(
                  opens: '18:00',
                  closes: '02:00',
                  overnight: true,
                ),
              ],
            ),
          ],
        ),
      );
      expect(days.map((d) => d.dayOfWeek), kIraqWeekOrder);
      expect(days.first.kind, HoursDayKind.hours);
      expect(days[1].kind, HoursDayKind.open24h);
      expect(days[2].kind, HoursDayKind.closed);
    });

    test('statusTone maps the spec colours', () {
      expect(statusTone(_open('17:00', 0)), HoursStatusTone.success);
      expect(
        statusTone(_open('17:00', 0, soon: true)),
        HoursStatusTone.warning,
      );
      expect(
        statusTone(
          const OpenStatusDto(state: OpenState.open, alwaysOpen: true),
        ),
        HoursStatusTone.success,
      );
      expect(statusTone(_closed('09:00', 1)), HoursStatusTone.muted);
      expect(
        statusTone(_closed('09:00', 0, soon: true)),
        HoursStatusTone.warning,
      );
      expect(
        statusTone(const OpenStatusDto(state: OpenState.temporarilyClosed)),
        HoursStatusTone.warning,
      );
      expect(
        statusTone(const OpenStatusDto(state: OpenState.permanentlyClosed)),
        HoursStatusTone.danger,
      );
      expect(statusTone(const OpenStatusDto()), isNull);
      expect(isStatusVisible(null), isFalse);
      expect(isStatusVisible(const OpenStatusDto()), isFalse);
      expect(isStatusVisible(_open('17:00', 0)), isTrue);
    });

    const today = TodayHoursDto(
      date: '2026-10-02',
      dayOfWeek: 5,
      kind: HoursDayKind.closed,
    );
    const lastNight = TodayHoursDto(
      date: '2026-10-01',
      dayOfWeek: 4,
      kind: HoursDayKind.hours,
      intervals: [
        HoursIntervalDto(opens: '18:00', closes: '03:00', overnight: true),
      ],
    );

    test(
      'hoursRowFor: «الليلة» in last night\'s tail, none when closed by status',
      () {
        final tail = ScopeHoursDto(
          status: _open('03:00', 0, dow: 5),
          today: today,
          lastNight: lastNight,
        );
        final row = hoursRowFor(tail)!;
        expect(row.label, HoursRowLabel.tonight);
        expect(row.day, same(lastNight));
        expect(hoursRowLabelText(row.label), 'الليلة');

        final plain = ScopeHoursDto(status: _closed('09:00', 1), today: today);
        expect(hoursRowFor(plain)!.label, HoursRowLabel.today);
        expect(hoursRowLabelText(HoursRowLabel.today), 'اليوم');

        for (final state in [
          OpenState.temporarilyClosed,
          OpenState.permanentlyClosed,
        ]) {
          expect(
            hoursRowFor(
              ScopeHoursDto(
                status: OpenStatusDto(state: state),
                today: today,
              ),
            ),
            isNull,
          );
        }
        expect(
          hoursRowFor(const ScopeHoursDto(status: OpenStatusDto())),
          isNull,
        );
      },
    );

    test(
      'Ramadan badge follows spanSeason while OPEN, today.season otherwise',
      () {
        final eidTail = ScopeHoursDto(
          status: const OpenStatusDto(
            state: OpenState.open,
            season: HoursSeason.regular,
            spanSeason: HoursSeason.ramadan,
          ),
          today: today,
        );
        expect(showsRamadanBadge(eidTail), isTrue);

        final regularTail = ScopeHoursDto(
          status: const OpenStatusDto(
            state: OpenState.open,
            season: HoursSeason.ramadan,
            spanSeason: HoursSeason.regular,
          ),
          today: const TodayHoursDto(
            date: '2026-10-02',
            dayOfWeek: 5,
            season: HoursSeason.ramadan,
          ),
        );
        expect(showsRamadanBadge(regularTail), isFalse);

        final closedInRamadan = ScopeHoursDto(
          status: _closed('20:00', 0),
          today: const TodayHoursDto(
            date: '2026-10-02',
            dayOfWeek: 5,
            season: HoursSeason.ramadan,
          ),
        );
        expect(showsRamadanBadge(closedInRamadan), isTrue);
        expect(
          showsRamadanBadge(
            ScopeHoursDto(
              status: const OpenStatusDto(state: OpenState.temporarilyClosed),
              today: closedInRamadan.today,
            ),
          ),
          isFalse,
        );
      },
    );

    test(
      '«أوقات رمضان تبدأ الليلة» on the eve, only while the badge is off',
      () {
        final eve = ScopeHoursDto(
          status: _closed('20:00', 0),
          today: const TodayHoursDto(
            date: '2027-02-07',
            dayOfWeek: 0,
            kind: HoursDayKind.hours,
            intervals: [HoursIntervalDto(opens: '09:00', closes: '14:00')],
            ramadanEveIntervals: [
              HoursIntervalDto(
                opens: '20:00',
                closes: '03:30',
                overnight: true,
              ),
            ],
          ),
        );
        expect(showsRamadanBadge(eve), isFalse);
        expect(showsRamadanStartsTonight(eve), isTrue);
        expect(
          showsRamadanStartsTonight(
            ScopeHoursDto(status: _open('14:00', 0), today: eve.today),
          ),
          isTrue,
        );
        expect(
          showsRamadanStartsTonight(
            ScopeHoursDto(status: _closed('20:00', 0), today: today),
          ),
          isFalse,
        );
      },
    );

    test(
      'no «تبدأ الليلة» hint while temporarily / permanently closed on the eve',
      () {
        const eveDay = TodayHoursDto(
          date: '2027-02-07',
          dayOfWeek: 0,
          kind: HoursDayKind.hours,
          intervals: [HoursIntervalDto(opens: '09:00', closes: '14:00')],
          ramadanEveIntervals: [
            HoursIntervalDto(opens: '20:00', closes: '03:30', overnight: true),
          ],
        );
        for (final state in [
          OpenState.temporarilyClosed,
          OpenState.permanentlyClosed,
          OpenState.unknown,
        ]) {
          expect(
            showsRamadanStartsTonight(
              ScopeHoursDto(
                status: OpenStatusDto(state: state),
                today: eveDay,
              ),
            ),
            isFalse,
            reason: '$state',
          );
        }
      },
    );

    test('"today" comes from summary.today.date, never the device clock', () {
      final oh = VenueOpeningHoursDto(
        timezone: 'Asia/Baghdad',
        evaluatedAt: '2026-10-02T00:30:00+03:00',
        summary: ScopeHoursDto(status: _closed('09:00', 0), today: today),
      );
      expect(baghdadToday(oh), '2026-10-02');
      expect(dayOfWeekOfYmd(baghdadToday(oh)), 5);

      final noHours = VenueOpeningHoursDto(
        timezone: 'Asia/Baghdad',
        evaluatedAt: '2026-10-02T00:30:00+03:00',
        summary: const ScopeHoursDto(status: OpenStatusDto()),
      );
      expect(baghdadToday(noHours), '2026-10-02');
    });

    test('date-only arithmetic helpers', () {
      final d = parseYmd('2026-12-31')!;
      expect(d.isUtc, isTrue);
      expect(formatYmd(d.add(const Duration(days: 1))), '2027-01-01');
      expect(parseYmd('31/12/2026'), isNull);
      expect(dayOfWeekOfYmd('2026-10-04'), 0);
      expect(dayOfWeekOfYmd('2026-10-03'), 6);
    });
  });
}
