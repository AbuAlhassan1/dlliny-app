import 'package:json_annotation/json_annotation.dart';

part 'invite_request.g.dart';

@JsonSerializable()
class InviteRequest {
  final List<String> userIds;
  final String? message;

  const InviteRequest({required this.userIds, this.message});

  factory InviteRequest.fromJson(Map<String, dynamic> json) =>
      _$InviteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$InviteRequestToJson(this);
}
