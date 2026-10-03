part of 'my_hangouts_bloc.dart';

sealed class MyHangoutsEvent {}

class GetMyHangouts extends MyHangoutsEvent {}

class GetMoreHangouts extends MyHangoutsEvent {}

class ResetMyHangouts extends MyHangoutsEvent {}
