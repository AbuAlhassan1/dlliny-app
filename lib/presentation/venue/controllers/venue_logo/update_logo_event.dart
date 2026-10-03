part of 'update_logo_bloc.dart';

sealed class UpdateLogoEvent {}

class UpdateVenueLogo extends UpdateLogoEvent {
  final String venueId;
  final File logo;
  UpdateVenueLogo({required this.venueId, required this.logo});
}

class DeleteVenueLogo extends UpdateLogoEvent {
  final String venueId;
  DeleteVenueLogo({required this.venueId});
}
