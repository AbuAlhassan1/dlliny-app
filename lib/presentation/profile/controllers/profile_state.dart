part of 'profile_bloc.dart';

sealed class ProfileState {
  final UserDto? user;
  final FollowStatus? followStatus;
  const ProfileState({this.user, this.followStatus});
}

final class ProfileInitial extends ProfileState {
  const ProfileInitial({super.user, super.followStatus});
}
final class ProfileLoading extends ProfileState {
  const ProfileLoading({super.user, super.followStatus});
}
final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({super.user, super.followStatus});
}
final class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message, {super.user, super.followStatus});
}

final class FollowUserLoading extends ProfileState {
  const FollowUserLoading({super.user, super.followStatus});
}
final class FollowUserUpdated extends ProfileState {
  const FollowUserUpdated({super.user, super.followStatus});
}
final class FollowUserError extends ProfileState {
  final String message;
  const FollowUserError(this.message, {super.user, super.followStatus});
}

final class UnfollowUserLoading extends ProfileState {
  const UnfollowUserLoading({super.user, super.followStatus});
}
final class UnfollowUserUpdated extends ProfileState {
  const UnfollowUserUpdated({super.user, super.followStatus});
}
final class UnfollowUserError extends ProfileState {
  final String message;
  const UnfollowUserError(this.message, {super.user, super.followStatus});
}
