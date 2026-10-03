import 'package:json_annotation/json_annotation.dart';

part 'admin_ghost_user_response.g.dart';

@JsonSerializable()
class AdminGhostUserResponse {
  final String id;
  final String username;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverUrl;
  final String? city;
  final String? district;
  final String? preferredLang;

  final bool isGhost;

  final String? createdByAdminId;

  final String createdAt;

  const AdminGhostUserResponse({
    required this.id,
    required this.username,
    this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverUrl,
    this.city,
    this.district,
    this.preferredLang,
    required this.isGhost,
    this.createdByAdminId,
    required this.createdAt,
  });

  factory AdminGhostUserResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminGhostUserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AdminGhostUserResponseToJson(this);
}
