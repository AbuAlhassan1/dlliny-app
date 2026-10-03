part of 'followers_following_bloc.dart';

sealed class FollowersFollowingState {}

final class FollowersFollowingInitial extends FollowersFollowingState {}

final class FollowersFollowingLoading extends FollowersFollowingState {}
final class FollowersFollowingLoaded extends FollowersFollowingState {}
final class FollowersFollowingError extends FollowersFollowingState {
  final String message;
  FollowersFollowingError(this.message);
}

final class FollowersFollowingMoreLoading extends FollowersFollowingState {}
final class FollowersFollowingMoreLoaded extends FollowersFollowingState {}
final class FollowersFollowingMoreError extends FollowersFollowingState {
  final String message;
  FollowersFollowingMoreError(this.message);
}
