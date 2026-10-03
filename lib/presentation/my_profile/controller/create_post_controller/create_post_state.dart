part of 'create_post_bloc.dart';

sealed class CreatePostState {}

final class CreatePostInitial extends CreatePostState {}
final class CreatePostLoading extends CreatePostState {}
final class CreatePostSuccess extends CreatePostState {}
final class CreatePostError extends CreatePostState {
  final String message;
  CreatePostError(this.message);
}

final class SearchToMentionLoading extends CreatePostState {}
final class SearchToMentionSuccess extends CreatePostState {
  final SearchResultResponse data;
  SearchToMentionSuccess(this.data);
}
final class SearchToMentionError extends CreatePostState {
  final String message;
  SearchToMentionError(this.message);
}