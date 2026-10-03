part of 'user_hangouts_bloc.dart';

sealed class UserHangoutsState {}

final class UserHangoutsInitial extends UserHangoutsState {}

final class UserHangoutsLoading extends UserHangoutsState {}
final class UserHangoutsLoaded extends UserHangoutsState {}
final class UserHangoutsError extends UserHangoutsState {
  final String message;
  UserHangoutsError(this.message);
}

final class UserHangoutsMoreLoading extends UserHangoutsState {}
final class UserHangoutsMoreLoaded extends UserHangoutsState {}
final class UserHangoutsMoreError extends UserHangoutsState {
  final String message;
  UserHangoutsMoreError(this.message);
}
