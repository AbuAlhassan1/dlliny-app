import 'package:json_annotation/json_annotation.dart';

part 'staff_response.g.dart';

@JsonSerializable()
class AssignableVenueRole {
  final String id;
  final String name;
  final String? description;

  const AssignableVenueRole({
    required this.id,
    required this.name,
    this.description,
  });

  factory AssignableVenueRole.fromJson(Map<String, dynamic> json) =>
      _$AssignableVenueRoleFromJson(json);
  Map<String, dynamic> toJson() => _$AssignableVenueRoleToJson(this);
}

@JsonSerializable()
class BusinessRoleSummary {
  final String id;
  final String name;
  final String? description;

  const BusinessRoleSummary({
    required this.id,
    required this.name,
    this.description,
  });

  factory BusinessRoleSummary.fromJson(Map<String, dynamic> json) =>
      _$BusinessRoleSummaryFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessRoleSummaryToJson(this);
}

@JsonSerializable()
class VenueStaffResponse {
  final String id;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String roleId;
  final String roleName;
  final DateTime grantedAt;

  const VenueStaffResponse({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.roleId,
    required this.roleName,
    required this.grantedAt,
  });

  factory VenueStaffResponse.fromJson(Map<String, dynamic> json) =>
      _$VenueStaffResponseFromJson(json);
  Map<String, dynamic> toJson() => _$VenueStaffResponseToJson(this);
}

@JsonSerializable()
class BusinessStaffResponse {
  final String id;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String roleId;
  final String roleName;
  final DateTime grantedAt;

  const BusinessStaffResponse({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    required this.roleId,
    required this.roleName,
    required this.grantedAt,
  });

  factory BusinessStaffResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessStaffResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BusinessStaffResponseToJson(this);
}
