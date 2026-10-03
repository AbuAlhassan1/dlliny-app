import 'package:json_annotation/json_annotation.dart';

part 'update_ghost_user_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateGhostUserRequest {
  final String? displayName;
  final String? bio;
  final String? avatarKey;
  final String? coverKey;
  final String? city;
  final String? district;
  final String? preferredLang;

  const UpdateGhostUserRequest({
    this.displayName,
    this.bio,
    this.avatarKey,
    this.coverKey,
    this.city,
    this.district,
    this.preferredLang,
  });

  factory UpdateGhostUserRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateGhostUserRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateGhostUserRequestToJson(this);
}
