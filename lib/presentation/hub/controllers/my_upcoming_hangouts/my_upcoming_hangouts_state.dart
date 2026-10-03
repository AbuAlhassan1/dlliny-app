part of 'my_upcoming_hangouts_bloc.dart';

sealed class MyUpcomingHangoutsState {
  const MyUpcomingHangoutsState();
}

final class MyUpcomingHangoutsInitial extends MyUpcomingHangoutsState {
  const MyUpcomingHangoutsInitial();
}

final class MyUpcomingHangoutsLoading extends MyUpcomingHangoutsState {
  const MyUpcomingHangoutsLoading();
}

final class MyUpcomingHangoutsEmpty extends MyUpcomingHangoutsState {
  const MyUpcomingHangoutsEmpty();
}

final class MyUpcomingHangoutsError extends MyUpcomingHangoutsState {
  final String message;
  const MyUpcomingHangoutsError(this.message);
}

final class MyUpcomingHangoutsLoaded extends MyUpcomingHangoutsState {
  final List<HangoutFeedItem> items;
  final bool hasMore;
  final bool loadingMore;

  const MyUpcomingHangoutsLoaded({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });
}
