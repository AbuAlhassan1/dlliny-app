part of 'user_posts_bloc.dart';

sealed class UserPostsEvent {}

class GetUserPosts extends UserPostsEvent {
  final String userId;
  GetUserPosts(this.userId);
}

class GetMoreUserPosts extends UserPostsEvent {
  final String userId;
  GetMoreUserPosts(this.userId);
}
