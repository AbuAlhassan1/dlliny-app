part of 'awaiting_review_bloc.dart';

sealed class AwaitingReviewState {
  const AwaitingReviewState();
}

final class AwaitingReviewInitial extends AwaitingReviewState {
  const AwaitingReviewInitial();
}

final class AwaitingReviewLoading extends AwaitingReviewState {
  const AwaitingReviewLoading();
}

final class AwaitingReviewLoaded extends AwaitingReviewState {
  final PendingVenueReviewResponse item;
  final bool isRefreshing;
  const AwaitingReviewLoaded(this.item, {this.isRefreshing = false});
}

final class AwaitingReviewConfirming extends AwaitingReviewState {
  final PendingVenueReviewResponse item;
  final int selectedRating;
  const AwaitingReviewConfirming({
    required this.item,
    required this.selectedRating,
  });
}

final class AwaitingReviewSubmitting extends AwaitingReviewState {
  final PendingVenueReviewResponse item;
  final int selectedRating;
  const AwaitingReviewSubmitting({
    required this.item,
    required this.selectedRating,
  });
}

final class AwaitingReviewSubmitError extends AwaitingReviewState {
  final PendingVenueReviewResponse item;
  final String message;
  const AwaitingReviewSubmitError({
    required this.item,
    required this.message,
  });
}

final class AwaitingReviewEmpty extends AwaitingReviewState {
  const AwaitingReviewEmpty();
}
