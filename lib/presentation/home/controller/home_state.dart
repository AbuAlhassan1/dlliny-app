part of 'home_bloc.dart';

sealed class HomeState {}

final class HomeInitial extends HomeState {}

final class HomeFeedTypeReady extends HomeState {
  final HomeFeedType feedType;
  HomeFeedTypeReady(this.feedType);
}
