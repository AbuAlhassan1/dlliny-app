part of 'user_hangouts_bloc.dart';

sealed class UserHangoutsEvent {}

class GetUserHangouts extends UserHangoutsEvent {
  final String userId;
  GetUserHangouts(this.userId);
}

class GetMoreUserHangouts extends UserHangoutsEvent {
  final String userId;
  GetMoreUserHangouts(this.userId);
}
