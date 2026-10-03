part of 'venue_branches_bloc.dart';

sealed class VenueBranchesEvent {}

class LoadVenueBranches extends VenueBranchesEvent {}

class CreateVenueBranch extends VenueBranchesEvent {
  final CreateVenueLocationRequest request;
  CreateVenueBranch(this.request);
}

class UpdateVenueBranch extends VenueBranchesEvent {
  final String locationId;
  final UpdateVenueLocationRequest request;
  UpdateVenueBranch({required this.locationId, required this.request});
}

class DeleteVenueBranch extends VenueBranchesEvent {
  final String locationId;
  DeleteVenueBranch(this.locationId);
}
