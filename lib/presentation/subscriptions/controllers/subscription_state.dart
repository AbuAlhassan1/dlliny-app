part of 'subscription_bloc.dart';

sealed class SubscriptionState {
  const SubscriptionState();
}

final class SubscriptionInitial extends SubscriptionState {
  const SubscriptionInitial();
}

final class SubscriptionLoading extends SubscriptionState {
  const SubscriptionLoading();
}

final class SubscriptionLoaded extends SubscriptionState {
  final List<MySubscriptionResponse> subs;
  const SubscriptionLoaded(this.subs);
}

final class SubscriptionStale extends SubscriptionState {
  final List<MySubscriptionResponse> subs;
  final String message;
  const SubscriptionStale({required this.subs, required this.message});
}

final class SubscriptionError extends SubscriptionState {
  final String message;
  const SubscriptionError(this.message);
}
