part of 'manage_hours_bloc.dart';

enum ManageHoursPhase { loading, loadFailed, ready, saving }

enum HoursConfirmReason {
  allClosed,

  branchNoRamadan,
}

sealed class ManageHoursEffect {
  const ManageHoursEffect();
}

final class HoursConfirmNeeded extends ManageHoursEffect {
  final HoursConfirmReason reason;
  const HoursConfirmNeeded(this.reason);
}

final class HoursSaveFailed extends ManageHoursEffect {
  final HoursEditorError error;
  const HoursSaveFailed(this.error);
}

final class HoursSaved extends ManageHoursEffect {
  const HoursSaved();
}

final class HoursAppliedToDays extends ManageHoursEffect {
  final int days;
  const HoursAppliedToDays(this.days);
}

final class HoursCleared extends ManageHoursEffect {
  const HoursCleared();
}

class HoursEditorError {
  final String? code;

  final String? detail;

  final List<HoursSegmentRef> conflict;

  final int? dayOfWeek;

  const HoursEditorError({
    this.code,
    this.detail,
    this.conflict = const [],
    this.dayOfWeek,
  });

  bool get isStatusError => code?.startsWith('STATUS_') ?? false;
}

class HoursApplyUndo {
  final String? scope;
  final HoursSeason season;
  final DraftWeek before;
  final DraftWeek after;

  const HoursApplyUndo({
    required this.scope,
    required this.season,
    required this.before,
    required this.after,
  });
}

class ManageHoursState {
  final ManageHoursPhase phase;

  final BusinessVenueHoursResponse? model;

  final Map<String?, ScopeDraft> initial;

  final Map<String?, ScopeDraft> drafts;

  final String? selectedScope;

  final HoursSeason season;

  final HoursEditorError? error;

  final ManageHoursEffect? effect;

  final bool changedOnServer;

  final HoursApplyUndo? applyUndo;

  const ManageHoursState({
    this.phase = ManageHoursPhase.loading,
    this.model,
    this.initial = const {},
    this.drafts = const {},
    this.selectedScope,
    this.season = HoursSeason.regular,
    this.error,
    this.effect,
    this.changedOnServer = false,
    this.applyUndo,
  });

  ScopeDraft? get draft => drafts[selectedScope];

  DraftWeek? weekOf(String? scope, HoursSeason season) =>
      drafts[scope]?.hours.week(season);

  bool get canUndoApply {
    final u = applyUndo;
    return u != null &&
        phase == ManageHoursPhase.ready &&
        identical(weekOf(u.scope, u.season), u.after);
  }

  String? get today => model?.baghdadToday;

  bool hoursDirty(String? scope) =>
      drafts[scope] != null && drafts[scope]!.hours != initial[scope]?.hours;

  bool statusDirty(String? scope) =>
      drafts[scope] != null && drafts[scope]!.status != initial[scope]?.status;

  bool scopeDirty(String? scope) => hoursDirty(scope) || statusDirty(scope);

  List<String?> get dirtyScopes => [
    for (final id in drafts.keys)
      if (scopeDirty(id)) id,
  ];

  bool get isDirty => drafts.keys.any(scopeDirty);

  bool get hasIncompleteIntervals =>
      drafts.keys.any((id) => hoursDirty(id) && !drafts[id]!.hours.isComplete);

  bool get canSave =>
      phase == ManageHoursPhase.ready && isDirty && !hasIncompleteIntervals;

  bool get showsIncompleteHint {
    final hours = draft?.hours;
    return hasIncompleteIntervals ||
        (hours != null && hours.own && !hours.isComplete);
  }

  List<EditableScopeHoursDto> get branches => model?.branches ?? const [];

  bool get showsScopeChips =>
      branches.length >= 2 || branches.any((b) => b.ownsHours || b.ownsStatus);

  ManageHoursState copyWith({
    ManageHoursPhase? phase,
    BusinessVenueHoursResponse? model,
    Map<String?, ScopeDraft>? initial,
    Map<String?, ScopeDraft>? drafts,
    String? selectedScope,
    bool selectVenue = false,
    HoursSeason? season,
    HoursEditorError? error,
    bool clearError = false,
    ManageHoursEffect? effect,
    bool? changedOnServer,
    HoursApplyUndo? applyUndo,
    bool clearApplyUndo = false,
  }) => ManageHoursState(
    phase: phase ?? this.phase,
    model: model ?? this.model,
    initial: initial ?? this.initial,
    drafts: drafts ?? this.drafts,
    selectedScope: selectVenue ? null : (selectedScope ?? this.selectedScope),
    season: season ?? this.season,
    error: clearError ? null : (error ?? this.error),
    effect: effect,
    changedOnServer: changedOnServer ?? this.changedOnServer,
    applyUndo: clearApplyUndo ? null : (applyUndo ?? this.applyUndo),
  );
}
