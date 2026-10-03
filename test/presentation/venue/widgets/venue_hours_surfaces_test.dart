import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_hours/venue_hours_bloc.dart';
import 'package:hangout/domain/dto/response/review_response.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';
import 'package:hangout/presentation/venue/widgets/venue_branches_section.dart';
import 'package:hangout/presentation/venue/widgets/venue_reviews_tab.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/hours_test_helpers.dart';
import '../../../helpers/locale_test_helper.dart';
import '../../../helpers/test_harness.dart';

class _FakeVenueBloc extends MockBloc<VenueEvent, VenueState>
    implements VenueBloc {}

class _FakeVenueHoursBloc extends MockBloc<VenueHoursEvent, VenueHoursState>
    implements VenueHoursBloc {}

final _karradaOpen = scopeOf(
  OpenStatusDto(
    state: OpenState.open,
    openNow: true,
    closesAt: moment('02:00', dayOffset: 1, dayOfWeek: 2, date: '2026-09-29'),
  ),
  locationId: 'karrada',
);

final _mansourTemp = scopeOf(
  const OpenStatusDto(
    state: OpenState.temporarilyClosed,
    openNow: false,
    reopensOn: '2026-10-12',
  ),
  locationId: 'mansour',
  statusSource: HoursSource.branch,
);

final _twoBranches = openingHoursOf(
  _karradaOpen,
  branches: [_karradaOpen, _mansourTemp],
);

VenueLocationResponse _location(String id, {bool primary = false}) =>
    VenueLocationResponse(
      id: id,
      venueId: 'venue-1',
      labelAr: primary ? 'الكرادة' : null,
      districtNameAr: primary ? 'الكرادة' : 'المنصور',
      latitude: 33.3,
      longitude: 44.4,
      isPrimary: primary,
      sortOrder: primary ? 0 : 1,
    );

void main() {
  setUpAll(() => loadTestLocale('ar'));

  group('map sheet: the tapped pin\'s branch (VenueScopeStatusLine)', () {
    Future<void> pump(
      WidgetTester tester,
      VenueOpeningHoursDto? hours,
      String? locationId,
    ) => tester.pumpWidget(
      hoursTestApp(
        Scaffold(
          body: VenueScopeStatusLine(
            openingHours: hours,
            locationId: locationId,
          ),
        ),
      ),
    );

    testWidgets('Mansour\'s pin shows Mansour\'s temporary closure', (
      tester,
    ) async {
      await pump(tester, _twoBranches, 'mansour');
      expect(find.textContaining('مغلق مؤقتاً'), findsOneWidget);
      expect(find.textContaining('مفتوح الآن'), findsNothing);
    });

    testWidgets('Karrada\'s pin, or no pin, shows the open primary', (
      tester,
    ) async {
      await pump(tester, _twoBranches, 'karrada');
      expect(find.text('مفتوح الآن · يغلق 2:00 ص'), findsOneWidget);
      await pump(tester, _twoBranches, null);
      expect(find.text('مفتوح الآن · يغلق 2:00 ص'), findsOneWidget);
    });

    testWidgets('a single-branch venue falls back to the summary', (
      tester,
    ) async {
      await pump(tester, openingHoursOf(_karradaOpen), 'karrada');
      expect(find.text('مفتوح الآن · يغلق 2:00 ص'), findsOneWidget);
    });

    testWidgets('UNKNOWN or no openingHours: no status line at all', (
      tester,
    ) async {
      await pump(
        tester,
        openingHoursOf(
          scopeOf(
            const OpenStatusDto(state: OpenState.unknown),
            hoursSource: HoursSource.none,
          ),
        ),
        'karrada',
      );
      expect(find.byType(VenueOpenStatusLine), findsNothing);
      await pump(tester, null, 'karrada');
      expect(find.byType(VenueOpenStatusLine), findsNothing);
    });
  });

  group('branch pills', () {
    late _FakeVenueBloc venueBloc;

    setUp(() async {
      await resetLocator();
      putSingleton<ApiService>(MockApiService());
      venueBloc = _FakeVenueBloc();
      when(() => venueBloc.state).thenReturn(
        GetVenueDetailsLoaded(
          venueWithHours(
            _twoBranches,
            locations: [
              _location('karrada', primary: true),
              _location('mansour'),
            ],
          ),
        ),
      );
    });

    tearDown(resetLocator);

    Color dotColor(WidgetTester tester, int index) {
      final dot = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(VenueOpenStatusDot).at(index),
              matching: find.byType(Container),
            )
            .first,
      );
      return (dot.decoration! as BoxDecoration).color!;
    }

    testWidgets('each pill carries its branch\'s status dot', (tester) async {
      await tester.pumpWidget(
        hoursTestApp(
          const Scaffold(body: VenueBranchesSection()),
          providers: [BlocProvider<VenueBloc>.value(value: venueBloc)],
        ),
      );
      expect(find.byType(VenueOpenStatusDot), findsNWidgets(2));
      final c = tester.element(find.byType(VenueBranchesSection)).c;
      expect(dotColor(tester, 0), c.success);
      expect(dotColor(tester, 1), c.warning);
    });

    testWidgets('a pill opens the branch sheet with that branch\'s hours', (
      tester,
    ) async {
      await tester.pumpWidget(
        hoursTestApp(
          const Scaffold(body: VenueBranchesSection()),
          providers: [BlocProvider<VenueBloc>.value(value: venueBloc)],
        ),
      );
      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      expect(find.text('أوقات العمل'), findsOneWidget);
      expect(find.text('مغلق مؤقتاً · يعود للعمل 12 أكتوبر'), findsOneWidget);
    });

    testWidgets('the dots follow the live hours bloc', (tester) async {
      final hoursBloc = VenueHoursBloc(venueId: 'venue-1');
      const perm = OpenStatusDto(state: OpenState.permanentlyClosed);
      hoursBloc.add(
        VenueHoursSeeded(
          openingHoursOf(
            scopeOf(perm, locationId: 'karrada'),
            branches: [
              scopeOf(perm, locationId: 'karrada'),
              scopeOf(perm, locationId: 'mansour'),
            ],
            evaluatedAt: '2026-09-28T22:00:00+03:00',
          ),
        ),
      );
      await tester.pumpWidget(
        hoursTestApp(
          const Scaffold(body: VenueBranchesSection()),
          providers: [
            BlocProvider<VenueBloc>.value(value: venueBloc),
            BlocProvider<VenueHoursBloc>.value(value: hoursBloc),
          ],
        ),
      );
      await tester.pump();
      final c = tester.element(find.byType(VenueBranchesSection)).c;
      expect(dotColor(tester, 0), c.danger);
      expect(dotColor(tester, 1), c.danger);
      unawaited(hoursBloc.close());
    });

    testWidgets('an open branch sheet repaints after a refresh', (
      tester,
    ) async {
      final api = serviceLocator.get<ApiService>() as MockApiService;
      final mansourOpen = scopeOf(
        OpenStatusDto(
          state: OpenState.open,
          openNow: true,
          closesAt: moment('23:00', dayOfWeek: 1, date: '2026-09-28'),
        ),
        locationId: 'mansour',
        statusSource: HoursSource.branch,
      );
      when(() => api.getVenueOpeningHours('venue-1')).thenAnswer(
        (_) async => apiOk(
          openingHoursOf(
            _karradaOpen,
            branches: [_karradaOpen, mansourOpen],
            evaluatedAt: '2026-09-28T22:00:00+03:00',
          ),
        ),
      );
      final hoursBloc = VenueHoursBloc(venueId: 'venue-1')
        ..add(VenueHoursSeeded(_twoBranches));
      await tester.pumpWidget(
        hoursTestApp(
          const Scaffold(body: VenueBranchesSection()),
          providers: [
            BlocProvider<VenueBloc>.value(value: venueBloc),
            BlocProvider<VenueHoursBloc>.value(value: hoursBloc),
          ],
        ),
      );
      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      expect(find.text('مغلق مؤقتاً · يعود للعمل 12 أكتوبر'), findsOneWidget);

      hoursBloc.add(const VenueHoursRefreshRequested());
      await tester.pump();
      await tester.pump();
      expect(hoursBloc.state, isA<VenueHoursReady>());
      expect(find.text('مغلق مؤقتاً · يعود للعمل 12 أكتوبر'), findsNothing);
      expect(find.text('مفتوح الآن · يغلق 11:00 م'), findsOneWidget);
      unawaited(hoursBloc.close());
    });

    testWidgets('a permanently closed branch shows no week in its sheet', (
      tester,
    ) async {
      final perm = scopeOf(
        const OpenStatusDto(state: OpenState.permanentlyClosed),
        locationId: 'mansour',
        statusSource: HoursSource.branch,
        regular: week([iv('09:00', '17:00')]),
      );
      final karrada = scopeOf(
        _karradaOpen.status,
        locationId: 'karrada',
        regular: week([iv('09:00', '17:00')]),
      );
      when(() => venueBloc.state).thenReturn(
        GetVenueDetailsLoaded(
          venueWithHours(
            openingHoursOf(karrada, branches: [karrada, perm]),
            locations: [
              _location('karrada', primary: true),
              _location('mansour'),
            ],
          ),
        ),
      );
      await tester.pumpWidget(
        hoursTestApp(
          const Scaffold(body: VenueBranchesSection()),
          providers: [BlocProvider<VenueBloc>.value(value: venueBloc)],
        ),
      );
      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      expect(find.text('مغلق نهائياً'), findsOneWidget);
      expect(find.text('السبت'), findsNothing);

      Navigator.of(tester.element(find.text('مغلق نهائياً'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('الكرادة').first);
      await tester.pumpAndSettle();
      expect(find.text('السبت'), findsOneWidget);
    });
  });

  group('pull to refresh on tab 0', () {
    late _FakeVenueBloc venueBloc;
    late _FakeVenueHoursBloc hoursBloc;
    late MockApiService api;

    setUpAll(() {
      registerFallbackValue(const VenueHoursRefreshRequested());
      registerFallbackValue(GetVenueDetails('venue-1'));
    });

    setUp(() async {
      await resetLocator();
      api = MockApiService();
      putSingleton<ApiService>(api);
      when(
        () => api.getVenueReviews('venue-1'),
      ).thenAnswer((_) async => apiOk(const <ReviewResponse>[]));
      when(
        () => api.getMyReviewForVenue('venue-1'),
      ).thenAnswer((_) async => apiOk<ReviewResponse>(null));
      venueBloc = _FakeVenueBloc();
      when(() => venueBloc.state).thenReturn(VenueInitial());
      hoursBloc = _FakeVenueHoursBloc();
      when(() => hoursBloc.state).thenReturn(const VenueHoursInitial());
    });

    tearDown(resetLocator);

    testWidgets('refreshes the live hours AND reloads the venue', (
      tester,
    ) async {
      await tester.pumpWidget(
        hoursTestApp(
          const Scaffold(body: VenueReviewsTab(venueId: 'venue-1')),
          providers: [
            BlocProvider<VenueBloc>.value(value: venueBloc),
            BlocProvider<VenueHoursBloc>.value(value: hoursBloc),
          ],
        ),
      );
      await tester.pumpAndSettle();
      verifyNever(() => hoursBloc.add(any()));
      verifyNever(() => venueBloc.add(any()));

      await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
      await tester.pumpAndSettle();

      final hoursEvent =
          verify(() => hoursBloc.add(captureAny())).captured.single
              as VenueHoursRefreshRequested;
      expect(hoursEvent.scheduled, isFalse);
      final venueEvent =
          verify(() => venueBloc.add(captureAny())).captured.single
              as GetVenueDetails;
      expect(venueEvent.id, 'venue-1');
      verify(() => api.getVenueReviews('venue-1')).called(2);
    });
  });
}
