import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/venue_hours_requests.dart';
import 'package:hangout/domain/dto/response/business_venue_hours_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/hours_draft.dart';
import 'package:hangout/presentation/venue/utils/hours_editor_validation.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';

part 'manage_hours_event.dart';
part 'manage_hours_state.dart';

class ManageHoursBloc extends Bloc<ManageHoursEvent, ManageHoursState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  final Set<HoursConfirmReason> _acknowledged = {};

  ManageHoursBloc({required this.venueId}) : super(const ManageHoursState()) {
    on<ManageHoursLoadRequested>(_onLoad);
    on<HoursScopeSelected>(_onScopeSelected);
    on<BranchHoursModeChanged>(_onBranchHoursMode);
    on<HoursSeasonSelected>(_onSeason);
    on<RamadanScheduleToggled>(_onRamadanToggled);
    on<HoursRangeApplied>(_onRangeApplied);
    on<HoursRangeUndone>(_onRangeUndone);
    on<HoursDayKindChanged>(_onDayKind);
    on<HoursIntervalAdded>(_onIntervalAdded);
    on<HoursIntervalChanged>(_onIntervalChanged);
    on<HoursIntervalRemoved>(_onIntervalRemoved);
    on<HoursDayCopiedToAll>(
      (e, emit) => _editWeek(emit, (w) => w.copyDayToAll(e.dayOfWeek)),
    );
    on<OperatingStatusChanged>(_onStatus);
    on<BranchStatusModeChanged>(_onBranchStatusMode);
    on<HoursSaveRequested>((e, emit) {
      _acknowledged.clear();
      return _save(emit);
    });
    on<HoursSaveConfirmed>((e, emit) {
      _acknowledged.add(e.reason);
      return _save(emit);
    });
    on<HoursClearRequested>(_onClear);
  }

  Future<void> _onLoad(
    ManageHoursLoadRequested event,
    Emitter<ManageHoursState> emit,
  ) async {
    emit(state.copyWith(phase: ManageHoursPhase.loading, clearError: true));
    try {
      final model = _unwrap(await _api.businessGetVenueHours(venueId));
      final drafts = <String?, ScopeDraft>{
        null: ScopeDraft.fromServer(model.venue),
        for (final b in model.branches) b.locationId: ScopeDraft.fromServer(b),
      };
      emit(
        ManageHoursState(
          phase: ManageHoursPhase.ready,
          model: model,
          initial: drafts,
          drafts: drafts,
        ),
      );
    } catch (error, stackTrace) {
      log('ManageHours load($venueId) failed: $error', stackTrace: stackTrace);
      final e = VenueApiError.from(error);
      emit(
        state.copyWith(
          phase: ManageHoursPhase.loadFailed,
          error: HoursEditorError(code: e.code, detail: e.detail),
        ),
      );
    }
  }

  void _onScopeSelected(
    HoursScopeSelected event,
    Emitter<ManageHoursState> emit,
  ) {
    if (!state.drafts.containsKey(event.locationId)) return;
    emit(
      state.copyWith(
        selectedScope: event.locationId,
        selectVenue: event.locationId == null,
        clearError: true,
      ),
    );
  }

  void _onSeason(HoursSeasonSelected event, Emitter<ManageHoursState> emit) {
    emit(state.copyWith(season: event.season));
  }

  void _onBranchHoursMode(
    BranchHoursModeChanged event,
    Emitter<ManageHoursState> emit,
  ) {
    final d = _editable;
    if (d == null || d.isVenue || d.hours.own == event.own) return;
    if (!event.own) {
      _put(emit, d.copyWith(hours: const HoursDraft(own: false)));
      return;
    }
    final stored = state.initial[d.locationId]!.hours;
    final venue = state.drafts[null]!.hours;
    _put(
      emit,
      d.copyWith(
        hours: stored.own
            ? stored
            : HoursDraft(
                own: true,
                regular: venue.regular ?? DraftWeek.starting(),
                ramadan: venue.ramadan,
              ),
      ),
    );
  }

  void _onRamadanToggled(
    RamadanScheduleToggled event,
    Emitter<ManageHoursState> emit,
  ) {
    final d = _editable;
    if (d == null || !d.hours.own) return;
    if (!event.enabled) {
      _put(emit, d.copyWith(hours: d.hours.copyWith(clearRamadan: true)));
      return;
    }
    if (d.hours.ramadan != null) return;
    final stored = state.initial[d.locationId]!.hours;
    final seed =
        (stored.own ? stored.ramadan : null) ??
        d.hours.regular ??
        DraftWeek.starting();
    _put(
      emit,
      d.copyWith(hours: d.hours.copyWith(ramadan: seed)),
      season: HoursSeason.ramadan,
    );
  }

  void _onDayKind(HoursDayKindChanged event, Emitter<ManageHoursState> emit) {
    _editWeek(emit, (w) {
      final day = w.day(event.dayOfWeek);
      final intervals =
          event.kind == HoursDayKind.hours && day.intervals.isEmpty
          ? const [DraftInterval.empty]
          : day.intervals;
      return w.withDay(day.copyWith(kind: event.kind, intervals: intervals));
    });
  }

  void _onIntervalAdded(
    HoursIntervalAdded event,
    Emitter<ManageHoursState> emit,
  ) {
    _editWeek(emit, (w) {
      final day = w.day(event.dayOfWeek);
      if (day.kind != HoursDayKind.hours ||
          day.intervals.length >= kMaxIntervalsPerDay) {
        return w;
      }
      return w.withDay(
        day.copyWith(intervals: [...day.intervals, DraftInterval.empty]),
      );
    });
  }

  void _onIntervalChanged(
    HoursIntervalChanged event,
    Emitter<ManageHoursState> emit,
  ) {
    _editWeek(emit, (w) {
      final day = w.day(event.dayOfWeek);
      if (event.index < 0 || event.index >= day.intervals.length) return w;
      final old = day.intervals[event.index];
      final intervals = [...day.intervals];
      intervals[event.index] = DraftInterval(
        opens: event.opens ?? old.opens,
        closes: event.closes ?? old.closes,
      );
      return w.withDay(day.copyWith(intervals: intervals));
    });
  }

  void _onIntervalRemoved(
    HoursIntervalRemoved event,
    Emitter<ManageHoursState> emit,
  ) {
    _editWeek(emit, (w) {
      final day = w.day(event.dayOfWeek);
      if (day.intervals.length <= 1 ||
          event.index < 0 ||
          event.index >= day.intervals.length) {
        return w;
      }
      return w.withDay(
        day.copyWith(intervals: [...day.intervals]..removeAt(event.index)),
      );
    });
  }

  void _onRangeApplied(
    HoursRangeApplied event,
    Emitter<ManageHoursState> emit,
  ) {
    void refuse(String why) => log(
      'ManageHours apply ${event.opens}–${event.closes} on ${event.days} '
      '(${event.mode.name}) refused: $why',
    );
    final d = _editable;
    if (d == null) return refuse('phase ${state.phase.name}');
    if (!d.hours.own) return refuse('the scope follows the venue default');
    if (event.days.isEmpty || event.days.any((dow) => dow < 0 || dow > 6)) {
      return refuse('days out of the week');
    }
    final rangeError = rangeErrorCode(event.opens, event.closes);
    if (rangeError != null) return refuse(rangeError);
    final season = state.season;
    final week = d.hours.week(season);
    if (week == null) return refuse('no ${season.name} week');
    final range = DraftInterval(opens: event.opens, closes: event.closes);
    final conflicts = week.applyConflicts(range, event.days, event.mode);
    if (conflicts.isNotEmpty) return refuse('conflicts $conflicts');
    final next = week.applyToDays(range, event.days, event.mode);
    _put(
      emit,
      d.copyWith(hours: d.hours.withWeek(season, next)),
      applyUndo: HoursApplyUndo(
        scope: d.locationId,
        season: season,
        before: week,
        after: next,
      ),
      effect: HoursAppliedToDays(event.days.length),
    );
  }

  void _onRangeUndone(HoursRangeUndone event, Emitter<ManageHoursState> emit) {
    final u = state.applyUndo;
    if (u == null) return;
    if (!state.canUndoApply) {
      emit(state.copyWith(clearApplyUndo: true));
      return;
    }
    final d = state.drafts[u.scope]!;
    emit(
      state.copyWith(
        drafts: {
          ...state.drafts,
          u.scope: d.copyWith(hours: d.hours.withWeek(u.season, u.before)),
        },
        selectedScope: u.scope,
        selectVenue: u.scope == null,
        season: u.season,
        clearApplyUndo: true,
        clearError: true,
      ),
    );
  }

  void _onStatus(OperatingStatusChanged event, Emitter<ManageHoursState> emit) {
    final d = _editable;
    if (d == null) return;
    _put(
      emit,
      d.copyWith(
        status: StatusDraft(
          own: true,
          status: event.status,
          reopensOn: event.status == VenueOperatingStatus.temporarilyClosed
              ? event.reopensOn
              : null,
        ),
      ),
    );
  }

  void _onBranchStatusMode(
    BranchStatusModeChanged event,
    Emitter<ManageHoursState> emit,
  ) {
    final d = _editable;
    if (d == null || d.isVenue || d.status.own == event.own) return;
    if (!event.own) {
      _put(emit, d.copyWith(status: const StatusDraft(own: false)));
      return;
    }
    final stored = state.initial[d.locationId]!.status;
    final venue = state.drafts[null]!.status;
    _put(
      emit,
      d.copyWith(
        status: stored.own
            ? stored
            : StatusDraft(
                own: true,
                status: venue.status ?? VenueOperatingStatus.open,
                reopensOn: venue.reopensOn,
              ),
      ),
    );
  }

  Future<void> _save(Emitter<ManageHoursState> emit) async {
    if (state.phase != ManageHoursPhase.ready || !state.isDirty) return;
    final today = state.today;
    if (today == null) return;
    final scopes = state.dirtyScopes;

    for (final id in scopes) {
      final d = state.drafts[id]!;
      if (state.hoursDirty(id) && d.hours.own) {
        for (final (season, week) in [
          (HoursSeason.regular, d.hours.regular),
          (HoursSeason.ramadan, d.hours.ramadan),
        ]) {
          if (week == null) continue;
          final error = validateWeeklySchedule(week.toInput().days);
          if (error != null) return _reject(emit, error, id, season: season);
        }
      }
      if (state.statusDirty(id)) {
        final s = d.status;
        final error = id == null
            ? validateOperatingStatus(s.status, s.reopensOn, today)
            : validateBranchOperatingStatus(
                s.own ? HoursScopeMode.own : HoursScopeMode.inherit,
                s.status,
                s.reopensOn,
                today,
              );
        if (error != null) return _reject(emit, error, id);
      }
    }

    final venueHasRamadan = state.drafts[null]?.hours.ramadan != null;
    for (final id in scopes) {
      if (!state.hoursDirty(id)) continue;
      final hours = state.drafts[id]!.hours;
      if (!hours.own) continue;
      if ((hours.regular?.allClosed ?? false) &&
          !_acknowledged.contains(HoursConfirmReason.allClosed)) {
        return _confirm(emit, HoursConfirmReason.allClosed, id);
      }
      final stored = state.initial[id]!.hours;
      if (id != null &&
          hours.ramadan == null &&
          venueHasRamadan &&
          (!stored.own || stored.ramadan != null) &&
          !_acknowledged.contains(HoursConfirmReason.branchNoRamadan)) {
        return _confirm(emit, HoursConfirmReason.branchNoRamadan, id);
      }
    }

    emit(state.copyWith(phase: ManageHoursPhase.saving, clearError: true));
    for (final id in scopes) {
      try {
        if (state.hoursDirty(id)) {
          _rebase(emit, await _putHours(id), id, hours: true);
        }
        if (state.statusDirty(id)) {
          _rebase(emit, await _putStatus(id), id, hours: false);
        }
      } catch (error, stackTrace) {
        log(
          'ManageHours save($venueId, $id) failed: $error',
          stackTrace: stackTrace,
        );
        final e = VenueApiError.from(error);
        final failure = HoursEditorError(code: e.code, detail: e.detail);
        emit(
          state.copyWith(
            phase: ManageHoursPhase.ready,
            selectedScope: id,
            selectVenue: id == null,
            error: failure,
            effect: HoursSaveFailed(failure),
          ),
        );
        return;
      }
    }
    emit(
      state.copyWith(phase: ManageHoursPhase.ready, effect: const HoursSaved()),
    );
  }

  Future<BusinessVenueHoursResponse> _putHours(String? id) async {
    final hours = state.drafts[id]!.hours;
    final stored = state.initial[id]!.hours;
    final removeRamadan =
        hours.ramadan == null && stored.own && stored.ramadan != null;
    if (id == null) {
      return _unwrap(
        await _api.businessUpdateVenueHours(
          venueId,
          UpdateVenueHoursRequest(
            regular: hours.regular!.toInput(),
            ramadan: hours.ramadan?.toInput(),
            removeRamadan: removeRamadan,
          ),
        ),
      );
    }
    return _unwrap(
      await _api.businessUpdateBranchHours(
        venueId,
        id,
        hours.own
            ? UpdateBranchHoursRequest(
                mode: HoursScopeMode.own,
                regular: hours.regular!.toInput(),
                ramadan: hours.ramadan?.toInput(),
                removeRamadan: removeRamadan,
              )
            : const UpdateBranchHoursRequest(mode: HoursScopeMode.inherit),
      ),
    );
  }

  Future<BusinessVenueHoursResponse> _putStatus(String? id) async {
    final s = state.drafts[id]!.status;
    if (id == null) {
      return _unwrap(
        await _api.businessUpdateVenueOperatingStatus(
          venueId,
          UpdateOperatingStatusRequest(
            status: s.status!,
            reopensOn: s.reopensOn,
          ),
        ),
      );
    }
    return _unwrap(
      await _api.businessUpdateBranchOperatingStatus(
        venueId,
        id,
        s.own
            ? UpdateBranchOperatingStatusRequest(
                mode: HoursScopeMode.own,
                status: s.status,
                reopensOn: s.reopensOn,
              )
            : const UpdateBranchOperatingStatusRequest(
                mode: HoursScopeMode.inherit,
              ),
      ),
    );
  }

  Future<void> _onClear(
    HoursClearRequested event,
    Emitter<ManageHoursState> emit,
  ) async {
    if (state.phase != ManageHoursPhase.ready) return;
    emit(state.copyWith(phase: ManageHoursPhase.saving, clearError: true));
    try {
      _rebase(
        emit,
        _unwrap(await _api.businessClearVenueHours(venueId)),
        null,
        hours: true,
      );
      emit(
        state.copyWith(
          phase: ManageHoursPhase.ready,
          effect: const HoursCleared(),
        ),
      );
    } catch (error) {
      final e = VenueApiError.from(error);
      final failure = HoursEditorError(code: e.code, detail: e.detail);
      emit(
        state.copyWith(
          phase: ManageHoursPhase.ready,
          error: failure,
          effect: HoursSaveFailed(failure),
        ),
      );
    }
  }

  ScopeDraft? get _editable =>
      state.phase == ManageHoursPhase.ready ? state.draft : null;

  void _put(
    Emitter<ManageHoursState> emit,
    ScopeDraft draft, {
    HoursSeason? season,
    HoursApplyUndo? applyUndo,
    ManageHoursEffect? effect,
  }) {
    emit(
      state.copyWith(
        drafts: {...state.drafts, draft.locationId: draft},
        season: season,
        clearError: true,
        applyUndo: applyUndo,
        effect: effect,
      ),
    );
  }

  void _editWeek(
    Emitter<ManageHoursState> emit,
    DraftWeek Function(DraftWeek week) change,
  ) {
    final d = _editable;
    if (d == null || !d.hours.own) return;
    final week = d.hours.week(state.season);
    if (week == null) return;
    final next = change(week);
    if (identical(next, week)) return;
    _put(emit, d.copyWith(hours: d.hours.withWeek(state.season, next)));
  }

  void _rebase(
    Emitter<ManageHoursState> emit,
    BusinessVenueHoursResponse model,
    String? id, {
    required bool hours,
  }) {
    final fresh = id == null ? model.venue : model.branch(id);
    if (fresh == null) {
      emit(state.copyWith(model: model, changedOnServer: true));
      return;
    }
    final saved = ScopeDraft.fromServer(fresh);
    ScopeDraft rebased(ScopeDraft d) => hours
        ? d.copyWith(hours: saved.hours)
        : d.copyWith(status: saved.status);
    emit(
      state.copyWith(
        model: model,
        initial: {...state.initial, id: rebased(state.initial[id]!)},
        drafts: {...state.drafts, id: rebased(state.drafts[id]!)},
        changedOnServer: true,
      ),
    );
  }

  void _reject(
    Emitter<ManageHoursState> emit,
    HoursValidationError error,
    String? id, {
    HoursSeason? season,
  }) {
    final failure = HoursEditorError(
      code: error.code,
      detail: error.detail,
      conflict: error.conflict,
      dayOfWeek: error.dayOfWeek,
    );
    emit(
      state.copyWith(
        selectedScope: id,
        selectVenue: id == null,
        season: season,
        error: failure,
        effect: HoursSaveFailed(failure),
      ),
    );
  }

  void _confirm(
    Emitter<ManageHoursState> emit,
    HoursConfirmReason reason,
    String? id,
  ) {
    emit(
      state.copyWith(
        selectedScope: id,
        selectVenue: id == null,
        season: HoursSeason.regular,
        effect: HoursConfirmNeeded(reason),
      ),
    );
  }

  static BusinessVenueHoursResponse _unwrap(
    ApiResponse<BusinessVenueHoursResponse> res,
  ) {
    final data = res.data;
    if (res.success && data != null) return data;
    throw VenueApiError.fromMessage(res.error);
  }
}
