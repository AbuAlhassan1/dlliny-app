part of 'create_hangout_bloc.dart';

sealed class CreateHangoutState {}

final class CreateHangoutInitial extends CreateHangoutState {}

final class CreateHangoutLoading extends CreateHangoutState {}

final class CreateHangoutSuccess extends CreateHangoutState {
  final HangoutResponse hangout;
  CreateHangoutSuccess(this.hangout);
}

final class CreateHangoutError extends CreateHangoutState {
  final String message;
  CreateHangoutError(this.message);
}
