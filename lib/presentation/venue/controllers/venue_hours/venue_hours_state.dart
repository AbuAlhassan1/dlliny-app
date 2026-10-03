part of 'venue_hours_bloc.dart';

sealed class VenueHoursState {
  const VenueHoursState();

  VenueOpeningHoursDto? get dto;
}

final class VenueHoursInitial extends VenueHoursState {
  const VenueHoursInitial();

  @override
  VenueOpeningHoursDto? get dto => null;
}

final class VenueHoursReady extends VenueHoursState {
  @override
  final VenueOpeningHoursDto dto;
  const VenueHoursReady(this.dto);
}

final class VenueHoursRefreshFailed extends VenueHoursState {
  final VenueOpeningHoursDto? lastGood;
  const VenueHoursRefreshFailed(this.lastGood);

  @override
  VenueOpeningHoursDto? get dto => lastGood;
}
