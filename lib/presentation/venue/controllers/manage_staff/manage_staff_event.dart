part of 'manage_staff_bloc.dart';

sealed class ManageStaffEvent {
  const ManageStaffEvent();
}

class LoadStaff extends ManageStaffEvent {
  const LoadStaff();
}

class AssignStaffSubmitted extends ManageStaffEvent {
  final String userId;
  final String roleId;
  const AssignStaffSubmitted({required this.userId, required this.roleId});
}

class RevokeStaffRequested extends ManageStaffEvent {
  final String userId;
  const RevokeStaffRequested(this.userId);
}
