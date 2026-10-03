part of 'user_posts_bloc.dart';

sealed class UserPostsState {}

final class UserPostsInitial extends UserPostsState {}

final class UserPostsLoading extends UserPostsState {}
final class UserPostsLoaded extends UserPostsState {}
final class UserPostsError extends UserPostsState {
  final String message;
  UserPostsError(this.message);
}

final class UserPostsMoreLoading extends UserPostsState {}
final class UserPostsMoreLoaded extends UserPostsState {}
final class UserPostsMoreError extends UserPostsState {
  final String message;
  UserPostsMoreError(this.message);
}
