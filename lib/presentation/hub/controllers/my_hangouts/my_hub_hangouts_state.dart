part of 'my_hub_hangouts_bloc.dart';

sealed class MyHubHangoutsState {
  const MyHubHangoutsState();
}

final class MyHubHangoutsInitial extends MyHubHangoutsState {
  const MyHubHangoutsInitial();
}

final class MyHubHangoutsLoading extends MyHubHangoutsState {
  const MyHubHangoutsLoading();
}

final class MyHubHangoutsEmpty extends MyHubHangoutsState {
  const MyHubHangoutsEmpty();
}

final class MyHubHangoutsError extends MyHubHangoutsState {
  final String message;
  const MyHubHangoutsError(this.message);
}

final class MyHubHangoutsLoaded extends MyHubHangoutsState {
  final List<HangoutFeedItem> items;
  final bool hasMore;

  final bool loadingMore;

  const MyHubHangoutsLoaded({
    required this.items,
    required this.hasMore,
    this.loadingMore = false,
  });
}
