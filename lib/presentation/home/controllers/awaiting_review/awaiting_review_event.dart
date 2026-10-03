part of 'awaiting_review_bloc.dart';

sealed class AwaitingReviewEvent {}

class LoadAwaitingReview extends AwaitingReviewEvent {}

class SelectRating extends AwaitingReviewEvent {
  final int stars;
  SelectRating(this.stars);
}

class CancelRating extends AwaitingReviewEvent {}

class ConfirmRating extends AwaitingReviewEvent {}
