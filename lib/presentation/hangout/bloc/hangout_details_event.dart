part of 'hangout_details_bloc.dart';

sealed class HangoutDetailsEvent {}

class LoadHangoutDetails extends HangoutDetailsEvent {
  final String hangoutId;
  LoadHangoutDetails(this.hangoutId);
}
