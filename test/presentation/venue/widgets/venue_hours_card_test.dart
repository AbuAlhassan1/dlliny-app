import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_hours/venue_hours_bloc.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_hours_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/hours_test_helpers.dart';
import '../../../helpers/locale_test_helper.dart';
import '../../../helpers/test_harness.dart';

class _FakeVenueBloc extends MockBloc<VenueEvent, VenueState>
    implements VenueBloc {}

const _fsi = '\u2068';
const _pdi = '\u2069';
String _iso(String a, String b) => '$_fsi$a$_pdi – $_fsi$b$_pdi';

VenueOpeningHoursDto _openLate({bool soon = false}) => openingHoursOf(
  scopeOf(
    OpenStatusDto(
      state: OpenState.open,
      openNow: true,
      closingSoon: soon,
      closesAt: soon
          ? moment('00:00', dayOffset: 1, dayOfWeek: 2, date: '2026-09-29')
          : moment('02:00', dayOffset: 1, dayOfWeek: 2, date: '2026-09-29'),
      spanOperatingDate: '2026-09-28',
      spanSeason: HoursSeason.regular,
    ),
    today: todayOf(
      '2026-09-28',
      1,
      intervals: [soon ? iv('09:00', '00:00') : iv('09:00', '02:00')],
    ),
    regular: week([iv('09:00', '02:00')]),
  ),
);

VenueOpeningHoursDto _closedOpensTomorrow() => openingHoursOf(
  scopeOf(
    OpenStatusDto(
      state: OpenState.closed,
      openNow: false,
      opensAt: moment('09:00', dayOffset: 1, dayOfWeek: 2, date: '2026-09-29'),
    ),
    today: todayOf('2026-09-28', 1, kind: HoursDayKind.closed),
    regular: week([iv('09:00', '17:00')], except: {1: closedDay(1)}),
  ),
);

VenueOpeningHoursDto _statusOnly(OpenStatusDto status) => openingHoursOf(
  scopeOf(
    status,
    today: todayOf('2026-09-28', 1, intervals: [iv('09:00', '02:00')]),
    regular: week([iv('09:00', '02:00')]),
  ),
);

VenueOpeningHoursDto _unknown() => openingHoursOf(
  scopeOf(
    const OpenStatusDto(state: OpenState.unknown),
    hoursSource: HoursSource.none,
    hoursUpdatedAt: null,
  ),
);

VenueOpeningHoursDto _regularTail() => openingHoursOf(
  scopeOf(
    OpenStatusDto(
      state: OpenState.open,
      openNow: true,
      closesAt: moment('03:00', dayOfWeek: 5, date: '2026-10-09'),
      spanOperatingDate: '2026-10-08',
      spanSeason: HoursSeason.regular,
    ),
    today: todayOf('2026-10-09', 5, kind: HoursDayKind.closed),
    lastNight: todayOf('2026-10-08', 4, intervals: [iv('18:00', '03:00')]),
    regular: fixtureA(),
  ),
  evaluatedAt: '2026-10-09T01:30:00+03:00',
);

VenueOpeningHoursDto _eidTail() => openingHoursOf(
  scopeOf(
    OpenStatusDto(
      state: OpenState.open,
      openNow: true,
      closesAt: moment('03:00', dayOfWeek: 3, date: '2027-03-10'),
      spanOperatingDate: '2027-03-09',
      spanSeason: HoursSeason.ramadan,
    ),
    today: todayOf('2027-03-10', 3, intervals: [iv('10:00', '23:00')]),
    lastNight: todayOf(
      '2027-03-09',
      2,
      intervals: [iv('20:00', '03:00')],
      season: HoursSeason.ramadan,
    ),
    regular: week([iv('10:00', '23:00')]),
    ramadan: week([iv('20:00', '03:00')]),
  ),
  evaluatedAt: '2027-03-10T01:00:00+03:00',
);

VenueOpeningHoursDto _eve() => openingHoursOf(
  scopeOf(
    OpenStatusDto(
      state: OpenState.closed,
      openNow: false,
      opensAt: moment('18:00', dayOfWeek: 0, date: '2027-02-07'),
    ),
    today: todayOf(
      '2027-02-07',
      0,
      intervals: [iv('18:00', '02:00')],
      eve: [iv('20:00', '03:00')],
    ),
    regular: week(
      [iv('10:00', '23:00')],
      except: {
        0: hoursDay(0, [iv('18:00', '02:00')]),
      },
    ),
    ramadan: week([iv('20:00', '03:00')]),
  ),
  window: const RamadanWindowDto(startsOn: '2027-02-08', endsOn: '2027-03-09'),
  evaluatedAt: '2027-02-07T12:00:00+03:00',
);

void main() {
  late _FakeVenueBloc venueBloc;

  setUp(() async {
    await resetLocator();
    putSingleton<ApiService>(MockApiService());
    venueBloc = _FakeVenueBloc();
    when(() => venueBloc.state).thenReturn(VenueInitial());
  });

  tearDown(resetLocator);

  Future<void> pumpCard(
    WidgetTester tester,
    VenueOpeningHoursDto? hours, {
    List<String> perms = const [],
    String locale = 'ar',
    VenueHoursBloc? hoursBloc,
    VoidCallback? onShowBranches,
  }) async {
    final venue = venueWithHours(hours);
    await tester.pumpWidget(
      hoursTestApp(
        Scaffold(
          body: SingleChildScrollView(
            child: VenueHoursCard(venue: venue, onShowBranches: onShowBranches),
          ),
        ),
        locale: locale,
        providers: [
          BlocProvider<AccessBloc>.value(value: accessWith(perms)),
          BlocProvider<VenueBloc>.value(value: venueBloc),
          if (hoursBloc != null)
            BlocProvider<VenueHoursBloc>.value(value: hoursBloc),
        ],
      ),
    );
    await tester.pump();
  }

  group('Arabic (RTL)', () {
    setUpAll(() => loadTestLocale('ar'));

    testWidgets('open late: status, today\'s row with the next-day hint', (
      tester,
    ) async {
      await pumpCard(tester, _openLate());
      expect(find.text('أوقات العمل'), findsOneWidget);
      expect(find.text('مفتوح الآن · يغلق 2:00 ص'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);
      expect(
        find.text('${_iso('9:00 ص', '2:00 ص')} (اليوم التالي)'),
        findsOneWidget,
      );
      expect(find.text('آخر تحديث 20 سبتمبر'), findsOneWidget);
      expect(find.text('أوقات رمضان مفعّلة'), findsNothing);
      expect(
        Directionality.of(tester.element(find.byType(VenueHoursCard))),
        TextDirection.rtl,
      );
      expect(find.text('تعديل الأوقات'), findsNothing);
    });

    testWidgets('closing soon names the time only', (tester) async {
      await pumpCard(tester, _openLate(soon: true));
      expect(find.text('يغلق قريباً · منتصف الليل'), findsOneWidget);
    });

    testWidgets('closed, opens tomorrow', (tester) async {
      await pumpCard(tester, _closedOpensTomorrow());
      expect(find.text('مغلق الآن · يفتح غداً 9:00 ص'), findsOneWidget);
      expect(find.text('اليوم'), findsOneWidget);
      expect(find.text('مغلق'), findsOneWidget);
    });

    testWidgets('temporarily closed with a date: no hours row', (tester) async {
      await pumpCard(
        tester,
        _statusOnly(
          const OpenStatusDto(
            state: OpenState.temporarilyClosed,
            openNow: false,
            reopensOn: '2026-10-12',
          ),
        ),
      );
      expect(find.text('مغلق مؤقتاً · يعود للعمل 12 أكتوبر'), findsOneWidget);
      expect(find.text('اليوم'), findsNothing);
      expect(find.text('الليلة'), findsNothing);
    });

    testWidgets('permanently closed: no hours row', (tester) async {
      await pumpCard(
        tester,
        _statusOnly(
          const OpenStatusDto(
            state: OpenState.permanentlyClosed,
            openNow: false,
          ),
        ),
      );
      expect(find.text('مغلق نهائياً'), findsOneWidget);
      expect(find.text('اليوم'), findsNothing);
    });

    testWidgets('permanently closed: no weekly table either', (tester) async {
      await pumpCard(
        tester,
        _statusOnly(
          const OpenStatusDto(
            state: OpenState.permanentlyClosed,
            openNow: false,
          ),
        ),
      );
      expect(find.text('عرض كل الأيام'), findsNothing);
      expect(find.text('السبت'), findsNothing);
    });

    testWidgets('temporarily closed keeps the week it reopens to', (
      tester,
    ) async {
      await pumpCard(
        tester,
        _statusOnly(
          const OpenStatusDto(
            state: OpenState.temporarilyClosed,
            openNow: false,
            reopensOn: '2026-10-12',
          ),
        ),
      );
      await tester.tap(find.text('عرض كل الأيام'));
      await tester.pumpAndSettle();
      expect(find.text('السبت'), findsOneWidget);
    });

    testWidgets('UNKNOWN is hidden from visitors', (tester) async {
      await pumpCard(tester, _unknown());
      expect(find.text('أوقات العمل'), findsNothing);
      expect(find.textContaining('أضف أوقات العمل'), findsNothing);
    });

    testWidgets('UNKNOWN shows hoursManage holders the call to action', (
      tester,
    ) async {
      await pumpCard(tester, _unknown(), perms: const [VenuePerm.hoursManage]);
      expect(
        find.text('أضف أوقات العمل ليعرف الزوار متى تكون مفتوحاً'),
        findsOneWidget,
      );
    });

    testWidgets('no openingHours (older backend): nothing, even for owners', (
      tester,
    ) async {
      await pumpCard(tester, null, perms: const [VenuePerm.hoursManage]);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('hoursManage holders get the edit link', (tester) async {
      await pumpCard(tester, _openLate(), perms: const [VenuePerm.hoursManage]);
      expect(find.text('تعديل الأوقات'), findsOneWidget);
    });

    testWidgets('the edit link is a 48 dp touch target', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(tester, _openLate(), perms: const [VenuePerm.hoursManage]);
      final rect = tester.getSemantics(find.text('تعديل الأوقات')).rect;
      expect(rect.height, greaterThanOrEqualTo(48));
      expect(rect.width, greaterThanOrEqualTo(48));
      semantics.dispose();
    });

    testWidgets('screen readers hear the status once', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCard(tester, _openLate());
      expect(find.bySemanticsLabel(RegExp('مفتوح الآن')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('A15: «الليلة» from lastNight, no badge on a regular tail', (
      tester,
    ) async {
      await pumpCard(tester, _regularTail());
      expect(find.text('مفتوح الآن · يغلق 3:00 ص'), findsOneWidget);
      expect(find.text('الليلة'), findsOneWidget);
      expect(
        find.text('${_iso('6:00 م', '3:00 ص')} (اليوم التالي)'),
        findsOneWidget,
      );
      expect(find.text('اليوم'), findsNothing);
      expect(find.text('أوقات رمضان مفعّلة'), findsNothing);
    });

    testWidgets('H7: the Ramadan tail of Eid night shows the badge', (
      tester,
    ) async {
      await pumpCard(tester, _eidTail());
      expect(find.text('أوقات رمضان مفعّلة'), findsOneWidget);
      expect(find.text('الليلة'), findsOneWidget);
    });

    testWidgets('I15: the eve shows «أول ليلة من رمضان» and the hint', (
      tester,
    ) async {
      await pumpCard(tester, _eve());
      expect(find.text('أول ليلة من رمضان'), findsOneWidget);
      expect(
        find.text('${_iso('8:00 م', '3:00 ص')} (اليوم التالي)'),
        findsOneWidget,
      );
      expect(find.text('أوقات رمضان تبدأ الليلة'), findsOneWidget);
      expect(find.text('أوقات رمضان مفعّلة'), findsNothing);
    });

    testWidgets('varies by branch: the hint scrolls to the branches', (
      tester,
    ) async {
      final base = _openLate();
      var tapped = false;
      await pumpCard(
        tester,
        openingHoursOf(
          base.summary,
          branches: [
            base.summary,
            scopeOf(
              base.summary.status,
              locationId: 'mansour',
              hoursSource: HoursSource.branch,
            ),
          ],
        ),
        onShowBranches: () => tapped = true,
      );
      await tester.tap(find.text('الأوقات تختلف حسب الفرع'));
      expect(tapped, isTrue);
    });

    testWidgets('the weekly table expands, Saturday first, today tagged', (
      tester,
    ) async {
      await pumpCard(tester, _closedOpensTomorrow());
      expect(find.text('السبت'), findsNothing);
      await tester.tap(find.text('عرض كل الأيام'));
      await tester.pumpAndSettle();
      expect(find.text('إخفاء'), findsOneWidget);
      final days = [
        'السبت',
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
      ];
      final tops = [for (final d in days) tester.getTopLeft(find.text(d)).dy];
      expect(tops, orderedEquals([...tops]..sort()));
      expect(find.text('اليوم'), findsNWidgets(2));
    });

    testWidgets('repaints from VenueHoursBloc, not the venue payload', (
      tester,
    ) async {
      final hoursBloc = VenueHoursBloc(venueId: 'venue-1');
      hoursBloc.add(VenueHoursSeeded(_closedOpensTomorrow()));
      await pumpCard(tester, _openLate(), hoursBloc: hoursBloc);
      expect(find.text('مغلق الآن · يفتح غداً 9:00 ص'), findsOneWidget);
      expect(find.text('مفتوح الآن · يغلق 2:00 ص'), findsNothing);
      unawaited(hoursBloc.close());
    });
  });

  group('English (LTR)', () {
    setUpAll(() => loadTestLocale('en'));

    testWidgets('open late', (tester) async {
      await pumpCard(tester, _openLate(), locale: 'en');
      expect(find.text('Open now · Closes 2:00 AM'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(VenueHoursCard))),
        TextDirection.ltr,
      );
    });

    testWidgets('closing soon', (tester) async {
      await pumpCard(tester, _openLate(soon: true), locale: 'en');
      expect(find.text('Closes soon · Midnight'), findsOneWidget);
    });

    testWidgets('closed, opens tomorrow', (tester) async {
      await pumpCard(tester, _closedOpensTomorrow(), locale: 'en');
      expect(find.text('Closed now · Opens tomorrow 9:00 AM'), findsOneWidget);
    });

    testWidgets('temporarily / permanently closed: no hours row', (
      tester,
    ) async {
      await pumpCard(
        tester,
        _statusOnly(
          const OpenStatusDto(
            state: OpenState.temporarilyClosed,
            reopensOn: '2026-10-12',
          ),
        ),
        locale: 'en',
      );
      expect(find.text('Temporarily closed · Reopens 12 Oct'), findsOneWidget);
      expect(find.text('Today'), findsNothing);

      await pumpCard(
        tester,
        _statusOnly(const OpenStatusDto(state: OpenState.permanentlyClosed)),
        locale: 'en',
      );
      expect(find.text('Permanently closed'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('UNKNOWN: hidden, CTA for hoursManage', (tester) async {
      await pumpCard(tester, _unknown(), locale: 'en');
      expect(find.text('Opening hours'), findsNothing);
      await pumpCard(
        tester,
        _unknown(),
        locale: 'en',
        perms: const [VenuePerm.hoursManage],
      );
      expect(find.textContaining('Add your opening hours'), findsOneWidget);
    });

    testWidgets('badge from spanSeason; «Tonight» and the eve row', (
      tester,
    ) async {
      await pumpCard(tester, _eidTail(), locale: 'en');
      expect(find.text('Ramadan hours in effect'), findsOneWidget);
      expect(find.text('Tonight'), findsOneWidget);

      await pumpCard(tester, _regularTail(), locale: 'en');
      expect(find.text('Ramadan hours in effect'), findsNothing);
      expect(find.text('Tonight'), findsOneWidget);

      await pumpCard(tester, _eve(), locale: 'en');
      expect(find.text('First night of Ramadan'), findsOneWidget);
    });
  });
}
