part of 'my_upcoming_hangouts_bloc.dart';

sealed class MyUpcomingHangoutsEvent {
  const MyUpcomingHangoutsEvent();
}

class LoadMyUpcomingHangouts extends MyUpcomingHangoutsEvent {
  const LoadMyUpcomingHangouts();
}

class LoadMoreMyUpcomingHangouts extends MyUpcomingHangoutsEvent {
  const LoadMoreMyUpcomingHangouts();
}
