part of 'comments_bloc.dart';

sealed class CommentsState {}

final class CommentsInitial extends CommentsState {}
final class CommentsLoading extends CommentsState {}
final class CommentsLoaded extends CommentsState {}
final class CommentsError extends CommentsState {
  final String message;
  CommentsError(this.message);
}

final class CommentsMoreLoading extends CommentsState {}
final class CommentsMoreLoaded extends CommentsState {}
final class CommentsMoreError extends CommentsState {
  final String message;
  CommentsMoreError(this.message);
}

final class AddingComment extends CommentsState {}
final class CommentAdded extends CommentsState {}
final class AddCommentError extends CommentsState {
  final String message;
  AddCommentError(this.message);
}

final class RepliesUpdated extends CommentsState {
  final String parentCommentId;
  RepliesUpdated(this.parentCommentId);
}

final class RepliesError extends CommentsState {
  final String parentCommentId;
  final String message;
  RepliesError(this.parentCommentId, this.message);
}

final class ReplyTargetChanged extends CommentsState {}
