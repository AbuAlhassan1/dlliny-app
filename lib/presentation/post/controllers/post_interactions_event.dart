part of 'post_interactions_bloc.dart';

sealed class PostInteractionsEvent {}

class BumpPostCommentsCount extends PostInteractionsEvent {
  final String postId;
  final int delta;
  final int currentCommentsCount;
  BumpPostCommentsCount({
    required this.postId,
    required this.delta,
    required this.currentCommentsCount,
  });
}

class ToggleLike extends PostInteractionsEvent {
  final String postId;
  final bool currentLikedByMe;
  final int currentLikesCount;
  ToggleLike({
    required this.postId,
    required this.currentLikedByMe,
    required this.currentLikesCount,
  });
}

class SubmitPostReport extends PostInteractionsEvent {
  final String postId;
  final String categoryId;
  final String? description;
  SubmitPostReport({
    required this.postId,
    required this.categoryId,
    this.description,
  });
}
