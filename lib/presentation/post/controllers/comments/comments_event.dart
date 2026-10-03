part of 'comments_bloc.dart';

sealed class CommentsEvent {}

class GetComments extends CommentsEvent {
  final String postId;
  GetComments(this.postId);
}

class GetMoreComments extends CommentsEvent {
  final String postId;
  GetMoreComments(this.postId);
}

class GetReplies extends CommentsEvent {
  final String postId;
  final String parentCommentId;
  GetReplies({required this.postId, required this.parentCommentId});
}

class GetMoreReplies extends CommentsEvent {
  final String postId;
  final String parentCommentId;
  GetMoreReplies({required this.postId, required this.parentCommentId});
}

class SetReplyTarget extends CommentsEvent {
  final String parentCommentId;
  final String authorUsername;
  SetReplyTarget({
    required this.parentCommentId,
    required this.authorUsername,
  });
}

class ClearReplyTarget extends CommentsEvent {}

class AddComment extends CommentsEvent {
  final String postId;
  final String body;

  final String? parentCommentId;

  AddComment({
    required this.postId,
    required this.body,
    this.parentCommentId,
  });
}

class DeleteComment extends CommentsEvent {
  final String postId;

  final String commentId;
  DeleteComment({required this.postId, required this.commentId});
}
