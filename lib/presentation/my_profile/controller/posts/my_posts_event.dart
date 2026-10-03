part of 'my_posts_bloc.dart';

sealed class MyPostsEvent {}
class GetMyPosts extends MyPostsEvent {}
class GetMorePosts extends MyPostsEvent {}

class DeleteMyPost extends MyPostsEvent {
  final String postId;
  DeleteMyPost(this.postId);
}

class ResetMyPosts extends MyPostsEvent {}
