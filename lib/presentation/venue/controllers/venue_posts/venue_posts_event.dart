part of 'venue_posts_bloc.dart';

sealed class VenuePostsEvent {
  const VenuePostsEvent();
}

class LoadVenuePosts extends VenuePostsEvent {
  const LoadVenuePosts();
}

class LoadNextVenuePostsPage extends VenuePostsEvent {
  const LoadNextVenuePostsPage();
}
