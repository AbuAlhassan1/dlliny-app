part of 'create_hangout_bloc.dart';

sealed class CreateHangoutEvent {}

class AddNewHangout extends CreateHangoutEvent {
  final CreateHangoutRequest body;
  final List<File>? files;
  final String? asVenueId;
  AddNewHangout(this.body, [this.files, this.asVenueId]);
}
