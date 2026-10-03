part of 'recent_attended_bloc.dart';

sealed class RecentAttendedState {
  const RecentAttendedState();
}

final class RecentAttendedInitial extends RecentAttendedState {
  const RecentAttendedInitial();
}

final class RecentAttendedLoading extends RecentAttendedState {
  const RecentAttendedLoading();
}

final class RecentAttendedLoaded extends RecentAttendedState {
  final List<HangoutResponse> items;
  const RecentAttendedLoaded(this.items);
}

final class RecentAttendedEmpty extends RecentAttendedState {
  const RecentAttendedEmpty();
}

final class RecentAttendedError extends RecentAttendedState {
  const RecentAttendedError();
}
