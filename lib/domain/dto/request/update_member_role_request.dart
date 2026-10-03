import 'package:json_annotation/json_annotation.dart';

import '../response/chat_enums.dart';

part 'update_member_role_request.g.dart';

@JsonSerializable()
class UpdateMemberRoleRequest {
  final ChatMemberRole role;

  const UpdateMemberRoleRequest({required this.role});

  factory UpdateMemberRoleRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateMemberRoleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMemberRoleRequestToJson(this);
}
