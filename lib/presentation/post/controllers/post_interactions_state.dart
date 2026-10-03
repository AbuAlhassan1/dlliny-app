part of 'post_interactions_bloc.dart';

sealed class PostInteractionsState {}

final class PostInteractionsInitial extends PostInteractionsState {}

final class PostInteractionUpdated extends PostInteractionsState {
  final String postId;
  PostInteractionUpdated(this.postId);
}

final class ReportSubmitting extends PostInteractionsState {}
final class ReportSubmitted extends PostInteractionsState {}
final class ReportFailed extends PostInteractionsState {
  final String message;
  ReportFailed(this.message);
}

class PostInteractionOverlay {
  final bool? likedByMe;
  final int? likesCount;
  final int? commentsCount;

  const PostInteractionOverlay({
    this.likedByMe,
    this.likesCount,
    this.commentsCount,
  });

  PostInteractionOverlay copyWith({
    bool? likedByMe,
    int? likesCount,
    int? commentsCount,
  }) {
    return PostInteractionOverlay(
      likedByMe: likedByMe ?? this.likedByMe,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
