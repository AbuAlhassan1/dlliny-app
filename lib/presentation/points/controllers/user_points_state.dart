part of 'user_points_bloc.dart';

sealed class UserPointsState {
  final UserPointsResponse? points;
  const UserPointsState({this.points});
}

final class UserPointsInitial extends UserPointsState {
  const UserPointsInitial();
}

final class UserPointsLoading extends UserPointsState {
  const UserPointsLoading({super.points});
}

final class UserPointsLoaded extends UserPointsState {
  final int? previousLevel;
  const UserPointsLoaded({super.points, this.previousLevel});
}

final class UserPointsError extends UserPointsState {
  final String message;
  const UserPointsError(this.message, {super.points});
}
