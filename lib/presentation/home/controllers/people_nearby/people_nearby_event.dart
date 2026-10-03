part of 'people_nearby_bloc.dart';

sealed class PeopleNearbyEvent {}

class LoadPeopleNearby extends PeopleNearbyEvent {}

class EnableNearbyDiscovery extends PeopleNearbyEvent {}

class DismissPerson extends PeopleNearbyEvent {
  final String userId;
  DismissPerson(this.userId);
}

class FollowPerson extends PeopleNearbyEvent {
  final String userId;
  FollowPerson(this.userId);
}
