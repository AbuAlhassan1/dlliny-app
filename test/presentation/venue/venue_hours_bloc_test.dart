import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/controllers/venue_hours/venue_hours_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/hours_test_helpers.dart';
import '../../helpers/test_harness.dart';

const _evaluated = '2026-09-28T21:40:00+03:00';

OpenStatusDto _open(
  String closes, {
  int offset = 0,
  bool soon = false,
  String date = '2026-09-28',
}) => OpenStatusDto(
  state: OpenState.open,
  openNow: true,
  closingSoon: soon,
  closesAt: moment(closes, dayOffset: offset, date: date),
  nextChangeAt: '${date}T$closes:00+03:00',
);

OpenStatusDto _closed(String opens, {bool soon = false}) => OpenStatusDto(
  state: OpenState.closed,
  openNow: false,
  openingSoon: soon,
  opensAt: moment(opens),
  nextChangeAt: '2026-09-28T$opens:00+03:00',
);

VenueOpeningHoursDto _oh(
  OpenStatusDto status, {
  List<OpenStatusDto> branches = const [],
  String evaluatedAt = _evaluated,
}) => openingHoursOf(
  scopeOf(status),
  evaluatedAt: evaluatedAt,
  branches: [
    for (var i = 0; i < branches.length; i++)
      scopeOf(branches[i], locationId: 'b$i'),
  ],
);

void main() {
  group('refreshDelay', () {
    test('OPEN until 02:00 tomorrow: Baghdad midnight comes first', () {
      final dto = _oh(_open('02:00', offset: 1, date: '2026-09-29'));
      expect(
        VenueHoursBloc.refreshDelay(dto),
        const Duration(hours: 2, minutes: 20, seconds: 5),
      );
    });

    test('OPEN until 23:30: an hour before closing (closing soon)', () {
      expect(
        VenueHoursBloc.refreshDelay(_oh(_open('23:30'))),
        const Duration(minutes: 50, seconds: 5),
      );
    });

    test('already closing soon: at the close itself', () {
      expect(
        VenueHoursBloc.refreshDelay(_oh(_open('22:10', soon: true))),
        const Duration(minutes: 30, seconds: 5),
      );
    });

    test('CLOSED, opens 23:00: an hour before (opening soon)', () {
      expect(
        VenueHoursBloc.refreshDelay(_oh(_closed('23:00'))),
        const Duration(minutes: 20, seconds: 5),
      );
    });

    test('a branch flipping earlier than the summary wins', () {
      final dto = _oh(
        _open('02:00', offset: 1, date: '2026-09-29'),
        branches: [_open('22:30', soon: true)],
      );
      expect(
        VenueHoursBloc.refreshDelay(dto),
        const Duration(minutes: 50, seconds: 5),
      );
    });

    test('never below 30 s', () {
      expect(
        VenueHoursBloc.refreshDelay(_oh(_open('21:40', soon: true))),
        VenueHoursBloc.minRefreshDelay,
      );
    });

    test('never above 6 h (an indefinite closure, just after midnight)', () {
      final dto = _oh(
        const OpenStatusDto(state: OpenState.temporarilyClosed, openNow: false),
        evaluatedAt: '2026-09-28T00:10:00+03:00',
      );
      expect(VenueHoursBloc.refreshDelay(dto), VenueHoursBloc.maxRefreshDelay);
    });

    test('next Baghdad midnight is 21:00Z of the Baghdad date', () {
      expect(
        VenueHoursBloc.nextBaghdadMidnight(_evaluated),
        DateTime.utc(2026, 9, 28, 21),
      );
      expect(
        VenueHoursBloc.nextBaghdadMidnight('2026-09-29T00:30:00+03:00'),
        DateTime.utc(2026, 9, 29, 21),
      );
    });
  });

  group('timer and refresh', () {
    late MockApiService api;

    setUp(() async {
      await resetLocator();
      api = MockApiService();
      putSingleton<ApiService>(api);
    });

    tearDown(resetLocator);

    testWidgets('re-fetches only the hours when the timer is due', (
      tester,
    ) async {
      final first = _oh(_open('23:30'));
      final refreshed = _oh(
        _open('23:30', soon: true),
        evaluatedAt: '2026-09-28T22:30:05+03:00',
      );
      when(
        () => api.getVenueOpeningHours('venue-1'),
      ).thenAnswer((_) async => apiOk(refreshed));

      final bloc = VenueHoursBloc(venueId: 'venue-1');
      bloc.add(VenueHoursSeeded(first));
      await tester.pump();
      expect(bloc.state, isA<VenueHoursReady>());

      await tester.pump(const Duration(minutes: 50));
      verifyNever(() => api.getVenueOpeningHours(any()));
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      verify(() => api.getVenueOpeningHours('venue-1')).called(1);
      expect(bloc.state.dto?.summary.status.closingSoon, isTrue);

      unawaited(bloc.close());
    });

    testWidgets('a failed refresh keeps the last good payload and retries', (
      tester,
    ) async {
      final good = _oh(_open('23:30'));
      when(() => api.getVenueOpeningHours('venue-1')).thenThrow(dioTimeout());

      final bloc = VenueHoursBloc(venueId: 'venue-1');
      bloc
        ..add(VenueHoursSeeded(good))
        ..add(const VenueHoursRefreshRequested());
      await tester.pump();
      await tester.pump();
      expect(bloc.state, isA<VenueHoursRefreshFailed>());
      expect(bloc.state.dto, same(good));

      await tester.pump(const Duration(seconds: 31));
      await tester.pump();
      verify(() => api.getVenueOpeningHours('venue-1')).called(2);

      unawaited(bloc.close());
    });

    testWidgets('an older payload never replaces a newer one', (tester) async {
      final newer = _oh(_open('23:30'));
      final older = _oh(
        _open('23:30'),
        evaluatedAt: '2026-09-28T21:00:00+03:00',
      );
      final bloc = VenueHoursBloc(venueId: 'venue-1');
      bloc
        ..add(VenueHoursSeeded(newer))
        ..add(VenueHoursSeeded(older));
      await tester.pump();
      expect(bloc.state.dto, same(newer));
      unawaited(bloc.close());
    });
  });

  group('unseeded, app resume and 404', () {
    late MockApiService api;

    setUp(() async {
      await resetLocator();
      api = MockApiService();
      putSingleton<ApiService>(api);
    });

    tearDown(resetLocator);

    Future<void> resume(WidgetTester tester) async {
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      await tester.pump();
    }

    testWidgets('app resume refreshes a seeded payload', (tester) async {
      when(
        () => api.getVenueOpeningHours('venue-1'),
      ).thenAnswer((_) async => apiOk(_oh(_open('23:30'))));
      final bloc = VenueHoursBloc(venueId: 'venue-1');
      bloc.add(VenueHoursSeeded(_oh(_open('23:30'))));
      await tester.pump();
      await resume(tester);
      verify(() => api.getVenueOpeningHours('venue-1')).called(1);
      unawaited(bloc.close());
    });

    testWidgets('never seeded: app resume does not call the server', (
      tester,
    ) async {
      final bloc = VenueHoursBloc(venueId: 'venue-1');
      await resume(tester);
      await tester.pump(const Duration(minutes: 30));
      verifyNever(() => api.getVenueOpeningHours(any()));
      unawaited(bloc.close());
    });

    testWidgets('never seeded: a pull still asks once; a 404 is not retried', (
      tester,
    ) async {
      when(
        () => api.getVenueOpeningHours('venue-1'),
      ).thenThrow(dioErrorWithStatus(404));
      final bloc = VenueHoursBloc(venueId: 'venue-1');
      bloc.add(const VenueHoursRefreshRequested());
      await tester.pump();
      await tester.pump();
      verify(() => api.getVenueOpeningHours('venue-1')).called(1);
      expect(bloc.state, isA<VenueHoursRefreshFailed>());
      expect(bloc.state.dto, isNull);

      await tester.pump(const Duration(minutes: 30));
      await resume(tester);
      verifyNever(() => api.getVenueOpeningHours(any()));
      unawaited(bloc.close());
    });

    testWidgets('never seeded: a failed pull is not retried either', (
      tester,
    ) async {
      when(() => api.getVenueOpeningHours('venue-1')).thenThrow(dioTimeout());
      final bloc = VenueHoursBloc(venueId: 'venue-1');
      bloc.add(const VenueHoursRefreshRequested());
      await tester.pump();
      await tester.pump();
      verify(() => api.getVenueOpeningHours('venue-1')).called(1);
      await tester.pump(const Duration(minutes: 30));
      verifyNever(() => api.getVenueOpeningHours(any()));
      unawaited(bloc.close());
    });

    testWidgets('seeded, then 404: no retry, no resume refresh until the '
        'next seed', (tester) async {
      when(
        () => api.getVenueOpeningHours('venue-1'),
      ).thenThrow(dioErrorWithStatus(404));
      final good = _oh(_open('23:30'));
      final bloc = VenueHoursBloc(venueId: 'venue-1');
      bloc
        ..add(VenueHoursSeeded(good))
        ..add(const VenueHoursRefreshRequested());
      await tester.pump();
      await tester.pump();
      verify(() => api.getVenueOpeningHours('venue-1')).called(1);
      expect(bloc.state.dto, same(good));

      await tester.pump(const Duration(hours: 1));
      await resume(tester);
      verifyNever(() => api.getVenueOpeningHours(any()));

      bloc.add(
        VenueHoursSeeded(
          _oh(_open('23:30'), evaluatedAt: '2026-09-28T21:50:00+03:00'),
        ),
      );
      await tester.pump();
      await resume(tester);
      verify(() => api.getVenueOpeningHours('venue-1')).called(1);
      unawaited(bloc.close());
    });
  });
}
