part of 'hangout_comments_bloc.dart';

sealed class HangoutCommentsState {}

final class HangoutCommentsInitial extends HangoutCommentsState {}
final class HangoutCommentsLoading extends HangoutCommentsState {}
final class HangoutCommentsLoaded extends HangoutCommentsState {}
final class HangoutCommentsError extends HangoutCommentsState {
  final String message;
  HangoutCommentsError(this.message);
}

final class HangoutCommentsMoreLoading extends HangoutCommentsState {}
final class HangoutCommentsMoreLoaded extends HangoutCommentsState {}
final class HangoutCommentsMoreError extends HangoutCommentsState {
  final String message;
  HangoutCommentsMoreError(this.message);
}

final class AddingHangoutComment extends HangoutCommentsState {}
final class HangoutCommentAdded extends HangoutCommentsState {}
final class AddHangoutCommentError extends HangoutCommentsState {
  final String message;
  AddHangoutCommentError(this.message);
}

final class HangoutRepliesUpdated extends HangoutCommentsState {
  final String parentCommentId;
  HangoutRepliesUpdated(this.parentCommentId);
}

final class HangoutRepliesError extends HangoutCommentsState {
  final String parentCommentId;
  final String message;
  HangoutRepliesError(this.parentCommentId, this.message);
}

final class HangoutReplyTargetChanged extends HangoutCommentsState {}
