part of 'home_bloc.dart';

sealed class HomeEvent {}

class HomeFeedTypeChanged extends HomeEvent {
  final HomeFeedType feedType;
  HomeFeedTypeChanged(this.feedType);
}
