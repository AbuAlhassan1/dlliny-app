part of 'people_nearby_bloc.dart';

sealed class PeopleNearbyState {
  const PeopleNearbyState();
}

final class PeopleNearbyInitial extends PeopleNearbyState {
  const PeopleNearbyInitial();
}

final class PeopleNearbyLoading extends PeopleNearbyState {
  const PeopleNearbyLoading();
}

final class PeopleNearbyNeedsOptIn extends PeopleNearbyState {
  const PeopleNearbyNeedsOptIn();
}

final class PeopleNearbyEnabling extends PeopleNearbyState {
  const PeopleNearbyEnabling();
}

final class PeopleNearbyLoaded extends PeopleNearbyState {
  final List<NearbySuggestionResponse> people;
  final Map<String, FollowStatus> followed;

  const PeopleNearbyLoaded(this.people, {this.followed = const {}});
}

final class PeopleNearbyEmpty extends PeopleNearbyState {
  const PeopleNearbyEmpty();
}

final class PeopleNearbyError extends PeopleNearbyState {
  const PeopleNearbyError();
}
