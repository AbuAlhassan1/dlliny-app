part of 'followers_following_bloc.dart';

sealed class FollowersFollowingEvent {}

class GetFollowList extends FollowersFollowingEvent {}

class GetMoreFollowList extends FollowersFollowingEvent {}
