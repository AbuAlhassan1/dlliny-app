import 'package:json_annotation/json_annotation.dart';

part 'update_username_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateUsernameRequest {
  final String username;

  const UpdateUsernameRequest({required this.username});

  factory UpdateUsernameRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateUsernameRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateUsernameRequestToJson(this);
}
