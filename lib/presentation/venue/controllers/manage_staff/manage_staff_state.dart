part of 'manage_staff_bloc.dart';

sealed class ManageStaffState {
  const ManageStaffState();
}

final class ManageStaffInitial extends ManageStaffState {
  const ManageStaffInitial();
}

final class ManageStaffLoading extends ManageStaffState {
  const ManageStaffLoading();
}

final class ManageStaffError extends ManageStaffState {
  final String message;
  const ManageStaffError(this.message);
}

final class ManageStaffLoaded extends ManageStaffState {
  final List<VenueStaffResponse> staff;
  const ManageStaffLoaded(this.staff);
}

final class ManageStaffMutating extends ManageStaffState {
  final List<VenueStaffResponse> staff;
  const ManageStaffMutating(this.staff);
}

final class ManageStaffActionSucceeded extends ManageStaffState {
  final List<VenueStaffResponse> staff;
  final String message;
  const ManageStaffActionSucceeded(this.staff, this.message);
}

final class ManageStaffActionFailed extends ManageStaffState {
  final List<VenueStaffResponse> staff;
  final String message;
  const ManageStaffActionFailed(this.staff, this.message);
}
