part of 'my_posts_bloc.dart';

sealed class MyPostsState {}

final class MyPostsInitial extends MyPostsState {}

final class MyPostsLoading extends MyPostsState {}
final class MyPostsLoaded extends MyPostsState {}
final class MyPostsError extends MyPostsState {
  final String message;
  MyPostsError(this.message);
}

final class MyPostsMoreLoading extends MyPostsState {}
final class MyPostsMoreLoaded extends MyPostsState {}
final class MyPostsMoreError extends MyPostsState {
  final String message;
  MyPostsMoreError(this.message);
}

final class MyPostDeleted extends MyPostsState {
  final String postId;
  MyPostDeleted(this.postId);
}
final class MyPostDeleteError extends MyPostsState {
  final String message;
  MyPostDeleteError(this.message);
}