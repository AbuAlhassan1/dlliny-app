part of 'hangout_comments_bloc.dart';

sealed class HangoutCommentsEvent {}

class GetHangoutComments extends HangoutCommentsEvent {
  final String hangoutId;
  GetHangoutComments(this.hangoutId);
}

class GetMoreHangoutComments extends HangoutCommentsEvent {
  final String hangoutId;
  GetMoreHangoutComments(this.hangoutId);
}

class GetHangoutReplies extends HangoutCommentsEvent {
  final String hangoutId;
  final String parentCommentId;
  GetHangoutReplies({
    required this.hangoutId,
    required this.parentCommentId,
  });
}

class GetMoreHangoutReplies extends HangoutCommentsEvent {
  final String hangoutId;
  final String parentCommentId;
  GetMoreHangoutReplies({
    required this.hangoutId,
    required this.parentCommentId,
  });
}

class SetHangoutReplyTarget extends HangoutCommentsEvent {
  final String parentCommentId;
  final String authorUsername;
  SetHangoutReplyTarget({
    required this.parentCommentId,
    required this.authorUsername,
  });
}

class ClearHangoutReplyTarget extends HangoutCommentsEvent {}

class AddHangoutComment extends HangoutCommentsEvent {
  final String hangoutId;
  final String body;

  final String? parentCommentId;

  AddHangoutComment({
    required this.hangoutId,
    required this.body,
    this.parentCommentId,
  });
}

class DeleteHangoutComment extends HangoutCommentsEvent {
  final String hangoutId;

  final String commentId;
  DeleteHangoutComment({
    required this.hangoutId,
    required this.commentId,
  });
}
