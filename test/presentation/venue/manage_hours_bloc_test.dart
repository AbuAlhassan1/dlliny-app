import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/venue_hours_requests.dart';
import 'package:hangout/domain/dto/response/business_venue_hours_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/hours_draft.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/manage_hours_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/hours_test_helpers.dart';
import '../../helpers/test_harness.dart';

const _allDays = {0, 1, 2, 3, 4, 5, 6};

final _regular = week([iv('09:00', '02:00')]);
final _ramadan = week([iv('20:00', '03:00')]);

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late MockApiService api;
  late ManageHoursBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      const UpdateVenueHoursRequest(regular: WeeklyScheduleInput(days: [])),
    );
    registerFallbackValue(const UpdateBranchHoursRequest(mode: 'OWN'));
    registerFallbackValue(const UpdateOperatingStatusRequest(status: 'OPEN'));
    registerFallbackValue(
      const UpdateBranchOperatingStatusRequest(mode: 'INHERIT'),
    );
  });

  setUp(() async {
    await resetLocator();
    api = MockApiService();
    putSingleton<ApiService>(api);
  });

  tearDown(() async {
    await bloc.close();
    await resetLocator();
  });

  Future<void> load(BusinessVenueHoursResponse model) async {
    when(
      () => api.businessGetVenueHours('venue-1'),
    ).thenAnswer((_) async => apiOk(model));
    bloc = ManageHoursBloc(venueId: 'venue-1')
      ..add(const ManageHoursLoadRequested());
    await _settle();
    expect(bloc.state.phase, ManageHoursPhase.ready);
  }

  void answerVenueHoursPut(BusinessVenueHoursResponse after) {
    when(
      () => api.businessUpdateVenueHours('venue-1', any()),
    ).thenAnswer((_) async => apiOk(after));
  }

  group('load', () {
    test(
      'a venue without hours starts from empty intervals, not closed',
      () async {
        await load(editorModel());
        final regular = bloc.state.draft!.hours.regular!;
        expect(regular.days.every((d) => d.kind == HoursDayKind.hours), isTrue);
        expect(regular.isComplete, isFalse);
        expect(bloc.state.isDirty, isFalse);
        expect(bloc.state.canSave, isFalse);
      },
    );

    test(
      'filling one day makes it dirty but Save waits for every day',
      () async {
        await load(editorModel());
        bloc.add(
          const HoursIntervalChanged(6, 0, opens: '09:00', closes: '17:00'),
        );
        await _settle();
        expect(bloc.state.isDirty, isTrue);
        expect(bloc.state.hasIncompleteIntervals, isTrue);
        expect(bloc.state.canSave, isFalse);

        bloc.add(const HoursRangeApplied('09:00', '17:00', _allDays));
        await _settle();
        expect(bloc.state.canSave, isTrue);
      },
    );

    test('a clean new scope already explains its greyed-out Save', () async {
      await load(editorModel());
      expect(bloc.state.hasIncompleteIntervals, isFalse);
      expect(bloc.state.showsIncompleteHint, isTrue);

      bloc.add(const HoursRangeApplied('09:00', '17:00', _allDays));
      await _settle();
      expect(bloc.state.showsIncompleteHint, isFalse);
      expect(bloc.state.canSave, isTrue);
    });

    test('stored complete hours: no incomplete hint', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      expect(bloc.state.showsIncompleteHint, isFalse);
    });

    test('a failed load offers a retry', () async {
      when(() => api.businessGetVenueHours('venue-1')).thenThrow(dioTimeout());
      bloc = ManageHoursBloc(venueId: 'venue-1')
        ..add(const ManageHoursLoadRequested());
      await _settle();
      expect(bloc.state.phase, ManageHoursPhase.loadFailed);
    });
  });

  group('save', () {
    test('a client validation error blocks the PUT', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      bloc
        ..add(const HoursIntervalAdded(1))
        ..add(const HoursIntervalChanged(1, 1, opens: '01:00', closes: '05:00'))
        ..add(const HoursSaveRequested());
      await _settle();
      verifyNever(() => api.businessUpdateVenueHours(any(), any()));
      expect(bloc.state.error?.code, 'HOURS_OVERLAP');
      expect(bloc.state.effect, isA<HoursSaveFailed>());
    });

    test('a server CODE comes back as that code', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      when(() => api.businessUpdateVenueHours('venue-1', any())).thenThrow(
        dioErrorWithMessage(
          'HOURS_INTERVAL_TOO_SHORT: Mon 10:00–10:10 is short',
        ),
      );
      bloc
        ..add(const HoursDayKindChanged(5, HoursDayKind.closed))
        ..add(const HoursSaveRequested());
      await _settle();
      verify(() => api.businessUpdateVenueHours('venue-1', any())).called(1);
      expect(bloc.state.error?.code, 'HOURS_INTERVAL_TOO_SHORT');
      expect(bloc.state.phase, ManageHoursPhase.ready);
      expect(bloc.state.isDirty, isTrue, reason: 'nothing was saved');
    });

    test(
      'a regular-only save sends neither ramadan nor removeRamadan',
      () async {
        await load(editorModel(venue: venueScope(regular: _regular)));
        answerVenueHoursPut(editorModel(venue: venueScope(regular: _regular)));
        bloc
          ..add(const HoursDayKindChanged(5, HoursDayKind.closed))
          ..add(const HoursSaveRequested());
        await _settle();
        final body =
            verify(
                  () => api.businessUpdateVenueHours('venue-1', captureAny()),
                ).captured.single
                as UpdateVenueHoursRequest;
        final json = body.toJson();
        expect(json.containsKey('ramadan'), isFalse);
        expect(json.containsKey('removeRamadan'), isFalse);
        verifyNever(() => api.businessUpdateVenueOperatingStatus(any(), any()));
        expect(bloc.state.effect, isA<HoursSaved>());
      },
    );

    test('removing a stored Ramadan week sends removeRamadan: true', () async {
      await load(
        editorModel(
          venue: venueScope(regular: _regular, ramadan: _ramadan),
        ),
      );
      answerVenueHoursPut(editorModel(venue: venueScope(regular: _regular)));
      bloc
        ..add(const HoursSeasonSelected(HoursSeason.ramadan))
        ..add(const RamadanScheduleToggled(false))
        ..add(const HoursSaveRequested());
      await _settle();
      final json =
          (verify(
                    () => api.businessUpdateVenueHours('venue-1', captureAny()),
                  ).captured.single
                  as UpdateVenueHoursRequest)
              .toJson();
      expect(json['removeRamadan'], isTrue);
      expect(json.containsKey('ramadan'), isFalse);
    });

    test('a Ramadan week in the draft is sent', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      answerVenueHoursPut(
        editorModel(
          venue: venueScope(regular: _regular, ramadan: _regular),
        ),
      );
      bloc
        ..add(const RamadanScheduleToggled(true))
        ..add(const HoursSaveRequested());
      await _settle();
      expect(bloc.state.season, HoursSeason.ramadan);
      final json =
          (verify(
                    () => api.businessUpdateVenueHours('venue-1', captureAny()),
                  ).captured.single
                  as UpdateVenueHoursRequest)
              .toJson();
      expect((json['ramadan'] as Map)['days'], hasLength(7));
      expect(json.containsKey('removeRamadan'), isFalse);
    });

    test('status and hours save independently', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      when(
        () => api.businessUpdateVenueOperatingStatus('venue-1', any()),
      ).thenAnswer(
        (_) async => apiOk(
          editorModel(
            venue: venueScope(
              regular: _regular,
              status: 'TEMPORARILY_CLOSED',
              reopensOn: '2026-10-12',
            ),
          ),
        ),
      );
      bloc
        ..add(
          const OperatingStatusChanged(
            VenueOperatingStatus.temporarilyClosed,
            reopensOn: '2026-10-12',
          ),
        )
        ..add(const HoursSaveRequested());
      await _settle();
      final body =
          verify(
                () => api.businessUpdateVenueOperatingStatus(
                  'venue-1',
                  captureAny(),
                ),
              ).captured.single
              as UpdateOperatingStatusRequest;
      expect(body.toJson(), {
        'status': 'TEMPORARILY_CLOSED',
        'reopensOn': '2026-10-12',
      });
      verifyNever(() => api.businessUpdateVenueHours(any(), any()));
      expect(bloc.state.isDirty, isFalse);
      expect(bloc.state.effect, isA<HoursSaved>());
    });

    test(
      'a reopen date on the server\'s today is rejected before the PUT',
      () async {
        await load(editorModel(venue: venueScope(regular: _regular)));
        bloc
          ..add(
            const OperatingStatusChanged(
              VenueOperatingStatus.temporarilyClosed,
              reopensOn: '2026-09-28',
            ),
          )
          ..add(const HoursSaveRequested());
        await _settle();
        expect(bloc.state.error?.code, 'STATUS_REOPEN_DATE_INVALID');
        verifyNever(() => api.businessUpdateVenueOperatingStatus(any(), any()));
      },
    );

    test('a week closed every day asks first', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      answerVenueHoursPut(
        editorModel(
          venue: venueScope(
            regular: week(
              [],
              except: {for (var d = 0; d < 7; d++) d: closedDay(d)},
            ),
          ),
        ),
      );
      for (var d = 0; d < 7; d++) {
        bloc.add(HoursDayKindChanged(d, HoursDayKind.closed));
      }
      bloc.add(const HoursSaveRequested());
      await _settle();
      expect(
        (bloc.state.effect as HoursConfirmNeeded).reason,
        HoursConfirmReason.allClosed,
      );
      verifyNever(() => api.businessUpdateVenueHours(any(), any()));

      bloc.add(const HoursSaveConfirmed(HoursConfirmReason.allClosed));
      await _settle();
      verify(() => api.businessUpdateVenueHours('venue-1', any())).called(1);
      expect(bloc.state.effect, isA<HoursSaved>());
    });
  });

  group('branches', () {
    BusinessVenueHoursResponse twoBranches({bool mansourOwn = false}) =>
        editorModel(
          venue: venueScope(regular: _regular, ramadan: _ramadan),
          branches: [
            branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
            branchScope(
              'mansour',
              districtNameAr: 'المنصور',
              ownHours: mansourOwn,
              regular: mansourOwn ? _regular : null,
            ),
          ],
        );

    test('switching a branch to its own hours seeds BOTH weeks', () async {
      await load(twoBranches());
      bloc
        ..add(const HoursScopeSelected('mansour'))
        ..add(const BranchHoursModeChanged(true));
      await _settle();
      final hours = bloc.state.draft!.hours;
      expect(hours.own, isTrue);
      expect(hours.regular, DraftWeek.fromDto(_regular));
      expect(hours.ramadan, DraftWeek.fromDto(_ramadan));
    });

    test(
      'OWN without the venue\'s Ramadan week asks first, then PUTs OWN',
      () async {
        await load(twoBranches());
        when(
          () => api.businessUpdateBranchHours('venue-1', 'mansour', any()),
        ).thenAnswer((_) async => apiOk(twoBranches(mansourOwn: true)));
        bloc
          ..add(const HoursScopeSelected('mansour'))
          ..add(const BranchHoursModeChanged(true))
          ..add(const RamadanScheduleToggled(false))
          ..add(const HoursSaveRequested());
        await _settle();
        expect(
          (bloc.state.effect as HoursConfirmNeeded).reason,
          HoursConfirmReason.branchNoRamadan,
        );
        verifyNever(() => api.businessUpdateBranchHours(any(), any(), any()));

        bloc.add(const HoursSaveConfirmed(HoursConfirmReason.branchNoRamadan));
        await _settle();
        final body =
            verify(
                  () => api.businessUpdateBranchHours(
                    'venue-1',
                    'mansour',
                    captureAny(),
                  ),
                ).captured.single
                as UpdateBranchHoursRequest;
        final json = body.toJson();
        expect(json['mode'], 'OWN');
        expect(json.containsKey('ramadan'), isFalse);
        expect(json.containsKey('removeRamadan'), isFalse);
      },
    );

    test('back to the venue\'s hours sends INHERIT only', () async {
      await load(twoBranches(mansourOwn: true));
      when(
        () => api.businessUpdateBranchHours('venue-1', 'mansour', any()),
      ).thenAnswer((_) async => apiOk(twoBranches()));
      bloc
        ..add(const HoursScopeSelected('mansour'))
        ..add(const BranchHoursModeChanged(false))
        ..add(const HoursSaveRequested());
      await _settle();
      final body =
          verify(
                () => api.businessUpdateBranchHours(
                  'venue-1',
                  'mansour',
                  captureAny(),
                ),
              ).captured.single
              as UpdateBranchHoursRequest;
      expect(body.toJson(), {'mode': 'INHERIT'});
    });

    test('a failure on a later scope keeps only that scope dirty', () async {
      await load(twoBranches());
      answerVenueHoursPut(twoBranches());
      when(
        () => api.businessUpdateBranchHours('venue-1', 'mansour', any()),
      ).thenThrow(
        dioErrorWithMessage(
          'BRANCH_NOT_FOUND: branch not found',
          statusCode: 404,
        ),
      );
      bloc
        ..add(const HoursDayKindChanged(5, HoursDayKind.closed))
        ..add(const HoursScopeSelected('mansour'))
        ..add(const BranchHoursModeChanged(true))
        ..add(const HoursSaveRequested());
      await _settle();
      verify(() => api.businessUpdateVenueHours('venue-1', any())).called(1);
      expect(bloc.state.scopeDirty(null), isFalse);
      expect(bloc.state.scopeDirty('mansour'), isTrue);
      expect(bloc.state.selectedScope, 'mansour');
      expect(bloc.state.changedOnServer, isTrue);
      expect(bloc.state.effect, isA<HoursSaveFailed>());
    });

    test('«نفس حالة المكان» sends a branch status INHERIT', () async {
      await load(
        editorModel(
          venue: venueScope(regular: _regular),
          branches: [
            branchScope('karrada', isPrimary: true),
            branchScope(
              'mansour',
              ownStatus: true,
              status: 'TEMPORARILY_CLOSED',
            ),
          ],
        ),
      );
      when(
        () => api.businessUpdateBranchOperatingStatus(
          'venue-1',
          'mansour',
          any(),
        ),
      ).thenAnswer((_) async => apiOk(twoBranches()));
      bloc
        ..add(const HoursScopeSelected('mansour'))
        ..add(const BranchStatusModeChanged(false))
        ..add(const HoursSaveRequested());
      await _settle();
      final body =
          verify(
                () => api.businessUpdateBranchOperatingStatus(
                  'venue-1',
                  'mansour',
                  captureAny(),
                ),
              ).captured.single
              as UpdateBranchOperatingStatusRequest;
      expect(body.toJson(), {'mode': 'INHERIT'});
    });
  });

  group('several days at once', () {
    DraftWeek regularOf(String? scope) =>
        bloc.state.drafts[scope]!.hours.regular!;

    test('replaces the chosen days only and reports how many', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      final before = regularOf(null);
      bloc.add(const HoursRangeApplied('10:00', '18:00', {6, 0, 1}));
      await _settle();
      final after = regularOf(null);
      for (final dow in [6, 0, 1]) {
        expect(after.day(dow).intervals, [
          const DraftInterval(opens: '10:00', closes: '18:00'),
        ]);
      }
      for (final dow in [2, 3, 4, 5]) {
        expect(identical(after.day(dow), before.day(dow)), isTrue);
      }
      expect((bloc.state.effect as HoursAppliedToDays).days, 3);
      expect(bloc.state.isDirty, isTrue);
      expect(bloc.state.canUndoApply, isTrue);
    });

    test('undo restores exactly the previous week', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      final before = regularOf(null);
      bloc.add(
        const HoursRangeApplied('03:00', '08:00', {
          1,
          2,
        }, mode: ApplyRangeMode.add),
      );
      await _settle();
      expect(regularOf(null).day(1).intervals, hasLength(2));

      bloc.add(const HoursRangeUndone());
      await _settle();
      expect(identical(regularOf(null), before), isTrue);
      expect(bloc.state.isDirty, isFalse);
      expect(bloc.state.applyUndo, isNull);
      expect(bloc.state.canUndoApply, isFalse);
    });

    test('a second apply is undone back to the first one\'s result', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      bloc.add(const HoursRangeApplied('10:00', '18:00', {6}));
      await _settle();
      final first = regularOf(null);
      bloc.add(const HoursRangeApplied('11:00', '19:00', {0}));
      await _settle();
      bloc.add(const HoursRangeUndone());
      await _settle();
      expect(identical(regularOf(null), first), isTrue);
    });

    test('a conflicting day refuses the whole apply', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      final before = regularOf(null);
      bloc.add(
        const HoursRangeApplied('01:00', '03:00', {
          1,
          2,
        }, mode: ApplyRangeMode.add),
      );
      bloc.add(const HoursRangeApplied('00:00', '00:00', {3}));
      await _settle();
      expect(identical(regularOf(null), before), isTrue);
      expect(bloc.state.effect, isNull);
      expect(bloc.state.applyUndo, isNull);
    });

    test('a later edit of that week makes the undo stale, not lost', () async {
      await load(editorModel(venue: venueScope(regular: _regular)));
      bloc
        ..add(const HoursRangeApplied('10:00', '18:00', {6}))
        ..add(const HoursDayKindChanged(2, HoursDayKind.closed));
      await _settle();
      expect(bloc.state.canUndoApply, isFalse);

      bloc.add(const HoursRangeUndone());
      await _settle();
      final w = regularOf(null);
      expect(w.day(6).intervals.single.opens, '10:00');
      expect(w.day(2).kind, HoursDayKind.closed);
      expect(bloc.state.applyUndo, isNull);
    });

    BusinessVenueHoursResponse branches() => editorModel(
      venue: venueScope(regular: _regular, ramadan: _ramadan),
      branches: [
        branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
        branchScope(
          'mansour',
          districtNameAr: 'المنصور',
          ownHours: true,
          regular: _regular,
          ramadan: _ramadan,
        ),
      ],
    );

    test('edits only the selected scope\'s selected season', () async {
      await load(branches());
      final venue = bloc.state.drafts[null]!.hours;
      final mansour = bloc.state.drafts['mansour']!.hours;
      bloc
        ..add(const HoursScopeSelected('mansour'))
        ..add(const HoursSeasonSelected(HoursSeason.ramadan))
        ..add(const HoursRangeApplied('21:00', '04:00', {5, 6}));
      await _settle();
      final now = bloc.state.drafts['mansour']!.hours;
      expect(now.ramadan!.day(5).intervals.single.closes, '04:00');
      expect(identical(now.regular, mansour.regular), isTrue);
      expect(identical(bloc.state.drafts[null]!.hours, venue), isTrue);
      expect(bloc.state.scopeDirty(null), isFalse);
    });

    test(
      'a branch\'s Ramadan week, applied to, saves with the new period',
      () async {
        await load(branches());
        when(
          () => api.businessUpdateBranchHours('venue-1', 'mansour', any()),
        ).thenAnswer((_) async => apiOk(branches()));
        bloc
          ..add(const HoursScopeSelected('mansour'))
          ..add(const HoursSeasonSelected(HoursSeason.ramadan))
          ..add(
            const HoursRangeApplied('05:00', '10:00', {
              5,
              6,
            }, mode: ApplyRangeMode.add),
          );
        await _settle();
        expect(bloc.state.effect, isA<HoursAppliedToDays>());
        bloc.add(const HoursSaveRequested());
        await _settle();

        verifyNever(() => api.businessUpdateVenueHours(any(), any()));
        final body =
            verify(
                  () => api.businessUpdateBranchHours(
                    'venue-1',
                    'mansour',
                    captureAny(),
                  ),
                ).captured.single
                as UpdateBranchHoursRequest;
        final json = body.toJson();
        expect(json['mode'], 'OWN');
        expect(json.containsKey('removeRamadan'), isFalse);
        expect(json['regular'], WeeklyScheduleInput.fromDto(_regular).toJson());
        final ramadan = (json['ramadan']['days'] as List)
            .cast<Map<String, dynamic>>();
        List<String> periods(int dow) => [
          for (final i in ramadan[dow]['intervals'] as List)
            '${i['opens']}–${i['closes']}',
        ];
        for (final dow in [5, 6]) {
          expect(ramadan[dow]['kind'], 'HOURS');
          expect(periods(dow), ['05:00–10:00', '20:00–03:00'], reason: '$dow');
        }
        for (final dow in [0, 1, 2, 3, 4]) {
          expect(periods(dow), ['20:00–03:00'], reason: '$dow');
        }
        expect(bloc.state.effect, isA<HoursSaved>());
      },
    );

    test('undo after switching scope and season still targets the original '
        'week, and brings it back on screen', () async {
      await load(branches());
      final ramadan = bloc.state.drafts[null]!.hours.ramadan!;
      bloc
        ..add(const HoursSeasonSelected(HoursSeason.ramadan))
        ..add(const HoursRangeApplied('19:00', '02:00', {4}))
        ..add(const HoursScopeSelected('mansour'))
        ..add(const HoursSeasonSelected(HoursSeason.regular));
      await _settle();
      expect(bloc.state.canUndoApply, isTrue);
      final mansour = bloc.state.drafts['mansour']!.hours;

      bloc.add(const HoursRangeUndone());
      await _settle();
      expect(
        identical(bloc.state.drafts[null]!.hours.ramadan, ramadan),
        isTrue,
      );
      expect(identical(bloc.state.drafts['mansour']!.hours, mansour), isTrue);
      expect(bloc.state.selectedScope, isNull);
      expect(bloc.state.season, HoursSeason.ramadan);
      expect(bloc.state.isDirty, isFalse);
    });

    test('an inheriting branch has no week to apply to', () async {
      await load(branches());
      bloc
        ..add(const HoursScopeSelected('karrada'))
        ..add(const HoursRangeApplied('10:00', '18:00', {0}));
      await _settle();
      expect(bloc.state.drafts['karrada']!.hours.regular, isNull);
      expect(bloc.state.effect, isNull);
      expect(bloc.state.isDirty, isFalse);
    });
  });

  group('clear all hours', () {
    BusinessVenueHoursResponse model({bool cleared = false}) => editorModel(
      venue: venueScope(regular: cleared ? null : _regular),
      branches: [
        branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
        branchScope('mansour', districtNameAr: 'المنصور'),
      ],
    );

    test(
      'stays open (HoursCleared) and keeps the other scopes\' edits',
      () async {
        await load(model());
        when(
          () => api.businessClearVenueHours('venue-1'),
        ).thenAnswer((_) async => apiOk(model(cleared: true)));
        bloc
          ..add(
            const OperatingStatusChanged(
              VenueOperatingStatus.temporarilyClosed,
            ),
          )
          ..add(const HoursScopeSelected('mansour'))
          ..add(const BranchHoursModeChanged(true))
          ..add(const HoursScopeSelected(null))
          ..add(const HoursClearRequested());
        await _settle();

        verify(() => api.businessClearVenueHours('venue-1')).called(1);
        expect(bloc.state.effect, isA<HoursCleared>());
        expect(bloc.state.effect, isNot(isA<HoursSaved>()));
        expect(bloc.state.phase, ManageHoursPhase.ready);
        expect(bloc.state.changedOnServer, isTrue);
        expect(bloc.state.hoursDirty(null), isFalse);
        expect(bloc.state.drafts[null]!.hours.regular, DraftWeek.starting());
        expect(bloc.state.statusDirty(null), isTrue);
        expect(bloc.state.hoursDirty('mansour'), isTrue);
      },
    );

    test('a failed clear keeps the weeks and reports it', () async {
      await load(model());
      when(
        () => api.businessClearVenueHours('venue-1'),
      ).thenThrow(dioTimeout());
      bloc.add(const HoursClearRequested());
      await _settle();
      expect(bloc.state.effect, isA<HoursSaveFailed>());
      expect(
        bloc.state.drafts[null]!.hours.regular,
        DraftWeek.fromDto(_regular),
      );
      expect(bloc.state.changedOnServer, isFalse);
    });
  });
}
