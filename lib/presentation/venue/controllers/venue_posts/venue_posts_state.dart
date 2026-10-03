part of 'venue_posts_bloc.dart';

sealed class VenuePostsState {
  const VenuePostsState();
}

final class VenuePostsInitial extends VenuePostsState {
  const VenuePostsInitial();
}

final class VenuePostsLoading extends VenuePostsState {
  const VenuePostsLoading();
}

final class VenuePostsError extends VenuePostsState {
  final String message;
  const VenuePostsError(this.message);
}

final class VenuePostsLoaded extends VenuePostsState {
  final List<PostResponse> items;
  final bool hasMore;
  const VenuePostsLoaded({required this.items, required this.hasMore});
}
