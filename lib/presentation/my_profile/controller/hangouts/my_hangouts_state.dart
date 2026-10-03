part of 'my_hangouts_bloc.dart';

sealed class MyHangoutsState {}

final class MyHangoutsInitial extends MyHangoutsState {}

final class MyHangoutsLoading extends MyHangoutsState {}

final class MyHangoutsLoaded extends MyHangoutsState {}

final class MyHangoutsError extends MyHangoutsState {
  final String message;
  MyHangoutsError(this.message);
}

final class MyHangoutsMoreLoading extends MyHangoutsState {}

final class MyHangoutsMoreLoaded extends MyHangoutsState {}

final class MyHangoutsMoreError extends MyHangoutsState {
  final String message;
  MyHangoutsMoreError(this.message);
}
