import 'package:json_annotation/json_annotation.dart';

part 'merge_ghost_user_request.g.dart';

@JsonSerializable(includeIfNull: false)
class MergeGhostUserRequest {
  final bool confirm;
  final String? keepUsername;
  final String? keepDisplayName;
  final String? keepBio;
  final String? keepAvatar;
  final String? keepCover;

  const MergeGhostUserRequest({
    required this.confirm,
    this.keepUsername,
    this.keepDisplayName,
    this.keepBio,
    this.keepAvatar,
    this.keepCover,
  });

  factory MergeGhostUserRequest.fromJson(Map<String, dynamic> json) =>
      _$MergeGhostUserRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MergeGhostUserRequestToJson(this);
}
