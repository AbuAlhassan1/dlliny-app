part of 'manage_hours_bloc.dart';

sealed class ManageHoursEvent {
  const ManageHoursEvent();
}

final class ManageHoursLoadRequested extends ManageHoursEvent {
  const ManageHoursLoadRequested();
}

final class HoursScopeSelected extends ManageHoursEvent {
  final String? locationId;
  const HoursScopeSelected(this.locationId);
}

final class BranchHoursModeChanged extends ManageHoursEvent {
  final bool own;
  const BranchHoursModeChanged(this.own);
}

final class HoursSeasonSelected extends ManageHoursEvent {
  final HoursSeason season;
  const HoursSeasonSelected(this.season);
}

final class RamadanScheduleToggled extends ManageHoursEvent {
  final bool enabled;
  const RamadanScheduleToggled(this.enabled);
}

final class HoursRangeApplied extends ManageHoursEvent {
  final String opens;
  final String closes;
  final Set<int> days;
  final ApplyRangeMode mode;
  const HoursRangeApplied(
    this.opens,
    this.closes,
    this.days, {
    this.mode = ApplyRangeMode.replace,
  });
}

final class HoursRangeUndone extends ManageHoursEvent {
  const HoursRangeUndone();
}

final class HoursDayKindChanged extends ManageHoursEvent {
  final int dayOfWeek;
  final HoursDayKind kind;
  const HoursDayKindChanged(this.dayOfWeek, this.kind);
}

final class HoursIntervalAdded extends ManageHoursEvent {
  final int dayOfWeek;
  const HoursIntervalAdded(this.dayOfWeek);
}

final class HoursIntervalChanged extends ManageHoursEvent {
  final int dayOfWeek;
  final int index;
  final String? opens;
  final String? closes;
  const HoursIntervalChanged(
    this.dayOfWeek,
    this.index, {
    this.opens,
    this.closes,
  });
}

final class HoursIntervalRemoved extends ManageHoursEvent {
  final int dayOfWeek;
  final int index;
  const HoursIntervalRemoved(this.dayOfWeek, this.index);
}

final class HoursDayCopiedToAll extends ManageHoursEvent {
  final int dayOfWeek;
  const HoursDayCopiedToAll(this.dayOfWeek);
}

final class OperatingStatusChanged extends ManageHoursEvent {
  final String status;
  final String? reopensOn;
  const OperatingStatusChanged(this.status, {this.reopensOn});
}

final class BranchStatusModeChanged extends ManageHoursEvent {
  final bool own;
  const BranchStatusModeChanged(this.own);
}

final class HoursSaveRequested extends ManageHoursEvent {
  const HoursSaveRequested();
}

final class HoursSaveConfirmed extends ManageHoursEvent {
  final HoursConfirmReason reason;
  const HoursSaveConfirmed(this.reason);
}

final class HoursClearRequested extends ManageHoursEvent {
  const HoursClearRequested();
}
