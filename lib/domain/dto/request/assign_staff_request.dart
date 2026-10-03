import 'package:json_annotation/json_annotation.dart';

part 'assign_staff_request.g.dart';

@JsonSerializable()
class AssignVenueStaffRequest {
  final String roleId;

  const AssignVenueStaffRequest({required this.roleId});

  factory AssignVenueStaffRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignVenueStaffRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AssignVenueStaffRequestToJson(this);
}

@JsonSerializable()
class AssignBusinessStaffRequest {
  final String roleId;

  const AssignBusinessStaffRequest({required this.roleId});

  factory AssignBusinessStaffRequest.fromJson(Map<String, dynamic> json) =>
      _$AssignBusinessStaffRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AssignBusinessStaffRequestToJson(this);
}
