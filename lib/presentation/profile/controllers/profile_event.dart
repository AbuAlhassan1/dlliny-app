part of 'profile_bloc.dart';

sealed class ProfileEvent {}

class GetUserProfile extends ProfileEvent {
  final String username;
  GetUserProfile(this.username);
}

class FollowUser extends ProfileEvent {}
class UnfollowUser extends ProfileEvent {}
