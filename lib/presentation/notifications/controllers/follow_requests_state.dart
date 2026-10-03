part of 'follow_requests_bloc.dart';

sealed class FollowRequestsState {}

final class FollowRequestsInitial extends FollowRequestsState {}

final class FollowRequestsLoading extends FollowRequestsState {}

final class FollowRequestsLoaded extends FollowRequestsState {}

final class FollowRequestsError extends FollowRequestsState {
  final String message;
  FollowRequestsError(this.message);
}
