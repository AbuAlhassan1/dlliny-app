import 'package:json_annotation/json_annotation.dart';

part 'create_ghost_user_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateGhostUserRequest {
  final String username;

  final String displayName;

  final String? bio;

  final String? avatarKey;

  final String? coverKey;

  final String? city;
  final String? district;

  final String? preferredLang;

  const CreateGhostUserRequest({
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarKey,
    this.coverKey,
    this.city,
    this.district,
    this.preferredLang,
  });

  factory CreateGhostUserRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateGhostUserRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateGhostUserRequestToJson(this);
}
