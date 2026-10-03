import 'package:json_annotation/json_annotation.dart';

part 'add_members_request.g.dart';

@JsonSerializable()
class AddMembersRequest {
  final List<String> userIds;

  const AddMembersRequest({required this.userIds});

  factory AddMembersRequest.fromJson(Map<String, dynamic> json) =>
      _$AddMembersRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AddMembersRequestToJson(this);
}
