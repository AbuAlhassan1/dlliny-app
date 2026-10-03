part of 'venue_hours_bloc.dart';

sealed class VenueHoursEvent {
  const VenueHoursEvent();
}

final class VenueHoursSeeded extends VenueHoursEvent {
  final VenueOpeningHoursDto hours;
  const VenueHoursSeeded(this.hours);
}

final class VenueHoursRefreshRequested extends VenueHoursEvent {
  final bool scheduled;

  const VenueHoursRefreshRequested({this.scheduled = false});
}
